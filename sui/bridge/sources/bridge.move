/// Copyright 2022 OmniBTC Authors. Licensed under Apache-2.0 License.
module owner::bridge {
    use std::string::{Self, String};
    use std::vector;

    use sui::coin::{Self, TreasuryCap, Coin};
    use sui::tx_context::{Self, TxContext};
    use sui::balance::{Self, Balance};
    use sui::object::{Self, UID, ID};
    use sui::event::emit;
    use sui::transfer;
    use sui::types;

    use owner::vec_queue::{Self, VecQueue};
    use owner::xbtc::{Self, XBTC};

    const MAX_MEMO_LENGTH: u64 = 255;
    const MAX_DEDUPLICATE_BUFFER: u64 = 10000;
    const MIN_WITHDRAW_AMOUNT: u64 = 150000; // 0.0015 BTC

    const EBRIDGE_ALREADY_INITIALIZED: u64 = 1;
    const EBRIDGE_MISMATCH_XBTC_BRIDGE: u64 = 2;
    const EBRIDGE_REQUIRE_AMDIN: u64 = 3;
    const EBRIDGE_REQUIRE_CONTROLLER: u64 = 4;
    const EBRIDGE_HAS_PAUSED: u64 = 5;
    const EBRIDGE_MEMO_TOO_LONG: u64 = 6;
    const EBRIDGE_HAS_DEPOSITED: u64 = 7;
    const EBRIDGE_INVALID_WITHDRAW: u64 = 8;

    /// Make sure initialize once
    struct BRIDGE_OTW has drop {}

    /// For deposit
    struct DepositEvent has copy, drop {
        receiver: address,
        amount: u64,
        memo: String
    }

    /// For withdraw
    struct WithdrawEvent has copy, drop  {
        sender: address,
        amount: u64,
        memo: String
    }

    /// Bridge Info
    struct Info has key {
        id: UID,
        has_paused: bool,
        min_withdraw: u64,
        controller: address,
        admin: address,
        xbtc_cap: ID,
        has_withdrew: Balance<XBTC>,
        deposits: VecQueue<String>,
    }

    /// Call by owner
    public entry fun initialize(
        xbtc_cap: TreasuryCap<XBTC>,
        controller: address,
        admin: address,
        ctx: &mut TxContext
    ) {
        assert!(
            types::is_one_time_witness(&BRIDGE_OTW{}),
            EBRIDGE_ALREADY_INITIALIZED
        );

        let info = Info {
            id: object::new(ctx),
            has_paused: false,
            min_withdraw: MIN_WITHDRAW_AMOUNT,
            controller,
            admin,
            xbtc_cap: object::id(&xbtc_cap),
            has_withdrew: balance::zero<XBTC>(),
            deposits: vec_queue::empty<String>(MAX_DEDUPLICATE_BUFFER)
        };

        transfer::transfer(xbtc_cap, admin);
        transfer::share_object(info);
    }

    /// Deposit XBTC
    /// Call by admin
    /// Note: memo used for deduplicate deposit
    public entry fun deposit(
        xbtc_cap: &mut TreasuryCap<XBTC>,
        info: &mut Info,
        receiver: address,
        amount: u64,
        memo: vector<u8>,
        ctx: &mut TxContext
    ) {
        assert!(
            !info.has_paused,
            EBRIDGE_HAS_PAUSED
        );
        assert!(
            info.xbtc_cap == object::id(xbtc_cap),
            EBRIDGE_MISMATCH_XBTC_BRIDGE
        );
        assert!(
            info.admin == tx_context::sender(ctx),
            EBRIDGE_REQUIRE_AMDIN
        );
        assert!(
            vector::length(&memo) <= MAX_MEMO_LENGTH,
            EBRIDGE_MEMO_TOO_LONG
        );

        let memo = string::utf8(memo);

        assert!(
            !vec_queue::contains(&info.deposits, &memo),
            EBRIDGE_HAS_DEPOSITED
        );

        xbtc::deposit(
            xbtc_cap,
            receiver,
            amount,
            ctx
        );

        // update memo buffer
        vec_queue::insert(
            &mut info.deposits,
            memo
        );

        // deposit event
        emit(
            DepositEvent {
                receiver,
                amount,
                memo
            }
        )
    }

    /// Withdraw XBTC to redeem BTC
    /// Call by user
    /// Note: memo used for receiver BTC address
    public entry fun withdraw(
        info: &mut Info,
        xbtc: &mut Coin<XBTC>,
        amount: u64,
        memo: vector<u8>,
        ctx: &mut TxContext
    ) {
        assert!(
            !info.has_paused,
            EBRIDGE_HAS_PAUSED
        );
        assert!(
            vector::length(&memo) <= MAX_MEMO_LENGTH,
            EBRIDGE_MEMO_TOO_LONG
        );
        assert!(
            amount >= info.min_withdraw,
            EBRIDGE_INVALID_WITHDRAW
        );

        let mut_xbtc = coin::balance_mut(xbtc);
        let withdraw_xbtc = coin::take(mut_xbtc, amount, ctx);
        coin::put(&mut info.has_withdrew, withdraw_xbtc);

        // withdraw event
        emit(
            WithdrawEvent {
                sender: tx_context::sender(ctx),
                amount,
                memo: string::utf8(memo)
            }
        )
    }

    /// Emergency pause
    /// Call by controller
    public entry fun set_pause(
        info: &mut Info,
        pause: bool,
        ctx: &mut TxContext
    ) {
        assert!(
            info.controller == tx_context::sender(ctx),
            EBRIDGE_REQUIRE_CONTROLLER
        );

        info.has_paused = pause
    }

    /// Set new min withdraw limit
    /// Call by admin
    public entry fun set_min_withdraw(
        info: &mut Info,
        min_withdraw: u64,
        ctx: &mut TxContext
    ) {
        assert!(
            info.controller == tx_context::sender(ctx),
            EBRIDGE_REQUIRE_AMDIN
        );

        info.min_withdraw = min_withdraw
    }

    #[test_only]
    fun bytes_to_hex_string(
        bytes: &vector<u8>
    ): String {
        use std::vector;

        let length = vector::length(bytes);
        let hex_symbols: vector<u8> = b"0123456789abcdef";
        let buffer = b"0x";

        let i: u64 = 0;
        while (i < length) {
            // little endian
            let byte = *vector::borrow(bytes, length - i - 1);

            vector::push_back(&mut buffer, *vector::borrow(&hex_symbols, (byte >> 4 & 0xf as u64)));
            vector::push_back(&mut buffer, *vector::borrow(&hex_symbols, (byte & 0xf as u64)));

            i = i + 1;
        };
        string::utf8(buffer)
    }

    #[test_only]
    public entry fun batch_append(
        info: &mut Info,
        start: u64,
        amount: u64,
    ) {
        use std::bcs;

        let i = start;
        while (i < start + amount) {
            let memo = bytes_to_hex_string(&bcs::to_bytes(&i));
            vec_queue::insert(&mut info.deposits, memo);
            i = i + 1;
        }
    }
}
