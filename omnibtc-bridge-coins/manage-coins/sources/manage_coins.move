/// Copyright 2022 OmniBTC Authors. Licensed under Apache-2.0 License.
module owner::ManageCoins {
    use std::string::{Self, String};
    use std::signer;
    use std::error;
    use std::option;
    use aptos_std::event::{emit_event, EventHandle};
    use aptos_std::account::new_event_handle;
    use aptos_std::type_info;
    use aptos_framework::coin::{
        Self, Coin, BurnCapability, FreezeCapability, MintCapability
    };

    use owner::iterable_table;

    const MAX_MEMO_LENGTH: u64 = 255;
    const MAX_DEDUPLICATE_BUFFER: u64 = 10000;
    const MIN_WITHDRAW_AMOUNT: u64 = 150000; // 0.0015 BTC

    const EMANAGECOIN_CAPABILITIES: u64 = 1;
    const EMANAGECOIN_INFO_ADDRESS_MISMATCH: u64 = 2;
    const EMANAGECOIN_MEMO_TOO_LONG: u64 = 3;
    const EMANAGECOIN_INFO_ALREADY_PUBLISHED: u64 = 4;
    const EMANAGECOIN_IS_PAUSED: u64 = 5;
    const EMANAGECOIN_IS_DEPOSITED: u64 = 6;
    const EMANAGECOIN_ALREADY_REGISTERED: u64 = 7;
    const EMANAGECOIN_REQUIRE_ADMIN: u64 = 8;
    const EMANAGECOIN_REQUIRE_CONTROLLER: u64 = 9;
    const EMANAGECOIN_INVALID_WITHDRAW: u64 = 10;

    /// Capabilities resource storing mint and burn capabilities.
    /// The resource is stored on the account that initialized coin `CoinType`.
    struct Capabilities<phantom CoinType> has key {
        burn_cap: BurnCapability<CoinType>,
        freeze_cap: FreezeCapability<CoinType>,
        mint_cap: MintCapability<CoinType>,
    }

    /// Colletct redeem requests
    struct HasWithdrew<phantom CoinType> has key {
        coin: Coin<CoinType>
    }

    /// Only use key for deduplicate
    struct NullValue has store, drop {}

    struct DepositEvent has store, drop {
        receiver: address,
        amount: u64,
        memo: String
    }

    struct WithdrawEvent has store, drop {
        sender: address,
        amount: u64,
        memo: String
    }

    /// Meta data
    struct Info has key {
        is_paused: bool,
        min_withdraw: u64,
        controller: address,
        admin: address,
        deposits: iterable_table::IterableTable<String, NullValue>,
        deposit_events: EventHandle<DepositEvent>,
        withdraw_events: EventHandle<WithdrawEvent>
    }

    /// A helper function that returns the address of Type.
    fun type_address<Type>(): address {
        type_info::account_address(&type_info::type_of<Type>())
    }

    /// Call by owner
    public entry fun initialize(
        owner: &signer,
        controller: address,
        admin: address
    ) {
        assert!(
            type_address<Info>() == signer::address_of(owner) ,
            error::invalid_argument(EMANAGECOIN_INFO_ADDRESS_MISMATCH),
        );
        assert!(
            !exists<Info>(signer::address_of(owner)),
            error::already_exists(EMANAGECOIN_INFO_ALREADY_PUBLISHED),
        );

        move_to(
            owner,
            Info {
                controller,
                admin,
                min_withdraw: MIN_WITHDRAW_AMOUNT,
                is_paused: false,
                deposits: iterable_table::new<String, NullValue>(),
                deposit_events: new_event_handle<DepositEvent>(owner),
                withdraw_events: new_event_handle<WithdrawEvent>(owner)
            }
        );
    }

    /// Issue a coin
    /// Call by admin(owner of coin)
    public entry fun issue<CoinType>(
        account: &signer,
        name: vector<u8>,
        symbol: vector<u8>,
        decimals: u8,
    ) acquires Info {
        assert!(
            admin() == signer::address_of(account),
            error::permission_denied(EMANAGECOIN_REQUIRE_ADMIN)
        );

        let (burn_cap, freeze_cap, mint_cap) = coin::initialize<CoinType>(
            account,
            string::utf8(name),
            string::utf8(symbol),
            decimals,
            true, // always monitor supply
        );

        move_to(
            account,
            Capabilities<CoinType>{
                burn_cap,
                freeze_cap,
                mint_cap,
            }
        );
    }

    // For cross chain assets(XBTC/XETH).
    // Allow user withdraw XBTC/XETH to redeem BTC/ETH
    // Call by admin
    public entry fun register_withdraw<CoinType>(
        account: &signer,
    ) acquires Info {
        assert!(
            admin() == signer::address_of(account),
            error::permission_denied(EMANAGECOIN_REQUIRE_ADMIN)
        );
        assert!(
            type_address<CoinType>() == signer::address_of(account),
            error::invalid_argument(EMANAGECOIN_INFO_ADDRESS_MISMATCH),
        );
        assert!(
            !exists<HasWithdrew<CoinType>>(signer::address_of(account)),
            error::already_exists(EMANAGECOIN_ALREADY_REGISTERED),
        );

        let has_withdrew = HasWithdrew<CoinType> {
            coin: coin::zero<CoinType>()
        };

        move_to(account, has_withdrew);
    }

    /// Deposit coin
    /// Call by admin
    /// Note: memo used for deduplicate deposit
    public entry fun deposit<CoinType>(
        account: &signer,
        receiver: address,
        amount: u64,
        memo: String,
    ) acquires Info, Capabilities {
        assert!(
            !is_paused(),
            error::invalid_state(EMANAGECOIN_IS_PAUSED)
        );

        let admin_addr = signer::address_of(account);
        assert!(
            admin() == admin_addr,
            error::permission_denied(EMANAGECOIN_REQUIRE_ADMIN)
        );
        assert!(
            exists<Capabilities<CoinType>>(admin_addr),
            error::not_found(EMANAGECOIN_CAPABILITIES),
        );
        assert!(
            string::length(&memo) <= MAX_MEMO_LENGTH,
            error::invalid_argument(EMANAGECOIN_MEMO_TOO_LONG)
        );
        assert!(
            !is_deposited(memo),
            error::already_exists(EMANAGECOIN_IS_DEPOSITED)
        );

        let capabilities = borrow_global<Capabilities<CoinType>>(admin_addr);
        let coins_minted = coin::mint(amount, &capabilities.mint_cap);
        coin::deposit(receiver, coins_minted);

        // deposit event
        append(receiver, amount, memo);
    }

    /// Withdraw coin to redeem source blockchain asset
    /// Call by user
    /// Note: memo used for receiver address(BTC/ETH)
    public entry fun withdraw<CoinType>(
        account: &signer,
        amount: u64,
        memo: String,
    ) acquires HasWithdrew, Info {
        assert!(
            !is_paused(),
            error::invalid_state(EMANAGECOIN_IS_PAUSED)
        );
        assert!(
            string::length(&memo) <= MAX_MEMO_LENGTH,
            error::invalid_argument(EMANAGECOIN_MEMO_TOO_LONG)
        );
        assert!(
            amount >= min_withdraw(),
            error::invalid_argument(EMANAGECOIN_INVALID_WITHDRAW)
        );

        let has_withdrew = borrow_global_mut<HasWithdrew<CoinType>>(type_address<CoinType>());
        let coin = coin::withdraw<CoinType>(account, amount);
        coin::merge(&mut has_withdrew.coin, coin);

        // withdraw event
        let info = borrow_global_mut<Info>(type_address<Info>());
        emit_event(
            &mut info.withdraw_events,
            WithdrawEvent {
                sender: signer::address_of(account),
                amount,
                memo
            }
        )
    }

    /// Register coin account
    /// The same as 0x1::manged_coin::register
    /// Call by user
    public entry fun register<CoinType>(
        account: &signer
    ) {
        coin::register<CoinType>(account);
    }

    /// Transfer coin
    /// The same as 0x1::coin::transfer
    /// Call by user
    public entry fun transfer<CoinType>(
        sender: &signer,
        receiver: address,
        amount: u64,
    ){
        coin::transfer<CoinType>(sender, receiver, amount)
    }

    /// Emergency pause
    /// Call by controller
    public entry fun set_pause(
        account: &signer,
        pause: bool
    ) acquires Info {
        assert!(
            controller() == signer::address_of(account),
            error::permission_denied(EMANAGECOIN_REQUIRE_CONTROLLER)
        );

        borrow_global_mut<Info>(type_address<Info>()).is_paused = pause
    }

    /// Set new min withdraw limit
    /// Call by admin
    public entry fun set_min_withdraw(
        account: &signer,
        min_withdraw: u64,
    ) acquires Info {
        let admin_addr = signer::address_of(account);
        assert!(
            admin() == admin_addr,
            error::permission_denied(EMANAGECOIN_REQUIRE_ADMIN)
        );

        borrow_global_mut<Info>(type_address<Info>()).min_withdraw = min_withdraw
    }

    fun is_paused(): bool acquires Info {
        borrow_global<Info>(type_address<Info>()).is_paused
    }

    fun append(
        receiver: address,
        amount: u64,
        memo: String
    ) acquires Info {
        let info = borrow_global_mut<Info>(type_address<Info>());
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

    fun is_deposited(
        memo: String
    ): bool acquires Info {
        let info = borrow_global<Info>(type_address<Info>());
        iterable_table::contains(&info.deposits, memo)
    }

    fun controller(): address acquires Info {
        let info = borrow_global<Info>(type_address<Info>());
        info.controller
    }

    fun admin(): address acquires Info {
        let info = borrow_global<Info>(type_address<Info>());
        info.admin
    }

    fun min_withdraw():u64 acquires Info {
        let info = borrow_global<Info>(type_address<Info>());
        info.min_withdraw
    }

    #[test_only]
    fun lookup(d: u8): u8 {
        if (d > 16) {
            return 0
        };

        if (d < 10) {
            // ASCII 48 is '0'
            return d + 48
        } else {
            // ASCII 65 is 'A'
            return d + 65
        }
    }

    #[test_only]
    fun into_hex(data: vector<u8>): vector<u8> {
        use std::vector;

        let len = vector::length(&data);
        let hex = vector::empty<u8>();
        let i = 0;

        while (i < len) {
            // little endian
            let index = len - i - 1;
            let high = *vector::borrow(&data, index) / 16;
            let low = *vector::borrow(&data, index) % 16;

            vector::push_back(&mut hex, lookup(high));
            vector::push_back(&mut hex, lookup(low));

            i = i + 1;
        };
        return hex
    }

    #[test_only]
    public entry fun batch_append(
        _account: &signer,
        start: u64,
        amount: u64,
    ) acquires Info {
        use std::bcs;

        let info = borrow_global_mut<Info>(type_address<Info>());
        let i = start;
        while (i < start + amount) {
            let raw = into_hex(bcs::to_bytes(&i));
            let memo = string::utf8(raw);
            iterable_table::add(&mut info.deposits, memo, NullValue{});
            i = i + 1;
        }
    }
}

