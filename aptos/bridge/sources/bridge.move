/// Copyright 2022 OmniBTC Authors. Licensed under Apache-2.0 License.
module owner::bridge {
    use std::string::{Self, String};
    use std::signer;
    use std::error;
    use std::option;
    use aptos_std::event::{emit_event, EventHandle};
    use aptos_std::account::new_event_handle;
    use aptos_framework::coin;
    use owner::iterable_table;
    use owner::xbtc::{Self, XBTC};

    const MAX_MEMO_LENGTH: u64 = 255;
    const MAX_DEDUPLICATE_BUFFER: u64 = 10000;
    const MIN_WITHDRAW_AMOUNT: u64 = 150000; // 0.0015 BTC

    const EBRIDGE_CAPABILITIES: u64 = 1;
    const EBRIDGE_REQUIRE_ADMIN: u64 = 2;
    const EBRIDGE_REQUIRE_CONTROLLER: u64 = 3;
    const EBRIDGE_INFO_ADDRESS_MISMATCH: u64 = 4;
    const EBRIDGE_MEMO_TOO_LONG: u64 = 5;
    const EBRIDGE_INFO_ALREADY_PUBLISHED: u64 = 6;
    const EBRIDGE_HAS_PAUSED: u64 = 7;
    const EBRIDGE_HAS_DEPOSITED: u64 = 8;
    const EBRIDGE_INVALID_WITHDRAW: u64 = 9;

    /// Only use key for deduplicate
    struct NullValue has store, drop {}

    /// For deposit
    struct DepositEvent has store, drop {
        receiver: address,
        amount: u64,
        memo: String
    }

    /// For withdraw
    struct WithdrawEvent has store, drop {
        sender: address,
        amount: u64,
        memo: String
    }

    /// Bridge Info
    struct Info has key {
        has_paused: bool,
        min_withdraw: u64,
        controller: address,
        admin: address,
        xbtc: coin::Coin<XBTC>,
        deposits: iterable_table::IterableTable<String, NullValue>,
        deposit_events: EventHandle<DepositEvent>,
        withdraw_events: EventHandle<WithdrawEvent>
    }

    /// Call by owner
    public entry fun initialize(
        owner: &signer,
        controller: address,
        admin: address
    ) {
        assert!(
            @owner == signer::address_of(owner) ,
            error::invalid_argument(EBRIDGE_INFO_ADDRESS_MISMATCH),
        );
        assert!(
            !exists<Info>(signer::address_of(owner)),
            error::already_exists(EBRIDGE_INFO_ALREADY_PUBLISHED),
        );

        move_to(
            owner,
            Info {
                controller,
                admin,
                min_withdraw: MIN_WITHDRAW_AMOUNT,
                has_paused: false,
                xbtc: coin::zero<XBTC>(),
                deposits: iterable_table::new<String, NullValue>(),
                deposit_events: new_event_handle<DepositEvent>(owner),
                withdraw_events: new_event_handle<WithdrawEvent>(owner)
            }
        );
    }

    /// Issue XBTC
    /// Call by admin
    public entry fun issue(
        account: &signer,
    ) acquires Info {
        assert!(
            admin() == signer::address_of(account),
            error::permission_denied(EBRIDGE_REQUIRE_ADMIN)
        );

        xbtc::issue(account)
    }

    /// Deposit XBTC
    /// Call by admin
    /// Note: memo used for deduplicate deposit
    public entry fun deposit(
        account: &signer,
        receiver: address,
        amount: u64,
        memo: String,
    ) acquires Info {
        assert!(
            !has_paused(),
            error::invalid_state(EBRIDGE_HAS_PAUSED)
        );
        assert!(
            admin() == signer::address_of(account),
            error::permission_denied(EBRIDGE_REQUIRE_ADMIN)
        );
        assert!(
            string::length(&memo) <= MAX_MEMO_LENGTH,
            error::invalid_argument(EBRIDGE_MEMO_TOO_LONG)
        );
        assert!(
            !has_deposited(memo),
            error::already_exists(EBRIDGE_HAS_DEPOSITED)
        );
        assert!(
            xbtc::has_capabilities(admin()),
            error::not_found(EBRIDGE_CAPABILITIES),
        );

        xbtc::deposit(admin(), receiver, amount);

        // deposit event
        append(receiver, amount, memo);
    }

    /// Withdraw XBTC to redeem BTC
    /// Call by user
    /// Note: memo used for receiver BTC address
    public entry fun withdraw(
        account: &signer,
        amount: u64,
        memo: String,
    ) acquires Info {
        assert!(
            !has_paused(),
            error::invalid_state(EBRIDGE_HAS_PAUSED)
        );
        assert!(
            string::length(&memo) <= MAX_MEMO_LENGTH,
            error::invalid_argument(EBRIDGE_MEMO_TOO_LONG)
        );
        assert!(
            amount >= min_withdraw(),
            error::invalid_argument(EBRIDGE_INVALID_WITHDRAW)
        );

        let info = borrow_global_mut<Info>(@owner);

        let coin = coin::withdraw<XBTC>(account, amount);
        coin::merge(&mut info.xbtc, coin);

        // withdraw event
        emit_event(
            &mut info.withdraw_events,
            WithdrawEvent {
                sender: signer::address_of(account),
                amount,
                memo
            }
        )
    }

    /// Emergency pause
    /// Call by controller
    public entry fun set_pause(
        account: &signer,
        pause: bool
    ) acquires Info {
        assert!(
            controller() == signer::address_of(account),
            error::permission_denied(EBRIDGE_REQUIRE_CONTROLLER)
        );

        borrow_global_mut<Info>(@owner).has_paused = pause
    }

    /// Set new min withdraw limit
    /// Call by admin
    public entry fun set_min_withdraw(
        account: &signer,
        min_withdraw: u64,
    ) acquires Info {
        assert!(
            admin() == signer::address_of(account),
            error::permission_denied(EBRIDGE_REQUIRE_ADMIN)
        );

        borrow_global_mut<Info>(@owner).min_withdraw = min_withdraw
    }

    fun has_paused(): bool acquires Info {
        borrow_global<Info>(@owner).has_paused
    }

    fun append(
        receiver: address,
        amount: u64,
        memo: String
    ) acquires Info {
        let info = borrow_global_mut<Info>(@owner);
        iterable_table::add(&mut info.deposits, memo, NullValue{});

        if (iterable_table::length(&info.deposits) >= MAX_DEDUPLICATE_BUFFER) {
            let head = iterable_table::head_key(&info.deposits);
            if (option::is_some(&head)) {
                iterable_table::remove(&mut info.deposits, option::extract(&mut head));
            }
        };

        emit_event(
            &mut info.deposit_events,
            DepositEvent{
                receiver,
                amount,
                memo
            }
        )
    }

    fun has_deposited(
        memo: String
    ): bool acquires Info {
        let info = borrow_global<Info>(@owner);
        iterable_table::contains(&info.deposits, memo)
    }

    public fun controller(): address acquires Info {
        borrow_global<Info>(@owner).controller
    }

    public fun admin(): address acquires Info {
        borrow_global<Info>(@owner).admin
    }

    public fun min_withdraw():u64 acquires Info {
        borrow_global<Info>(@owner).min_withdraw
    }

    #[test_only]
    fun bytes_to_hex_string(bytes: &vector<u8>): String {
        use std::vector;

        let hex_symbols: vector<u8> = b"0123456789abcdef";

        let length = vector::length(bytes);
        let buffer = b"0x";

        let i: u64 = 0;
        while (i < length) {
            let byte = *vector::borrow(bytes, i);
            vector::push_back(&mut buffer, *vector::borrow(&mut hex_symbols, (byte >> 4 & 0xf as u64)));
            vector::push_back(&mut buffer, *vector::borrow(&mut hex_symbols, (byte & 0xf as u64)));
            i = i + 1;
        };
        string::utf8(buffer)
    }

    #[test_only]
    public entry fun batch_append(
        _account: &signer,
        start: u64,
        amount: u64,
    ) acquires Info {
        use std::bcs;

        let info = borrow_global_mut<Info>(@owner);
        let i = start;
        while (i < start + amount) {
            let memo = bytes_to_hex_string(&bcs::to_bytes(&i));
            iterable_table::add(&mut info.deposits, memo, NullValue{});
            i = i + 1;
        }
    }
}
