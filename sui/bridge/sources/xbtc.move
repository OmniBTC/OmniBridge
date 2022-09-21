/// Copyright 2022 OmniBTC Authors. Licensed under Apache-2.0 License.
module owner::xbtc {
    use std::string::{utf8, String};
    use std::vector;

    use sui::coin::{Self, Coin, TreasuryCap};
    use sui::tx_context::{Self, TxContext};
    use sui::object::{Self, UID};
    use sui::transfer;

    friend owner::bridge;

    /// XBTC define
    ////////////////////////
    struct XBTC has drop {}
    ////////////////////////

    /// XBTC meta info
    struct XBTCInfo has key {
        id: UID,
        name: String,
        symbol: String,
        decimals: u8,
    }

    /// Register XBTC while publishing
    /// Call by bridge
    /// TODO: refactor after merged this pr: https://github.com/MystenLabs/sui/pull/4558
    fun init(
        xbtc: XBTC,
        ctx: &mut TxContext
    ) {
        let treasury_cap = coin::create_currency<XBTC>(xbtc, ctx);

        transfer::transfer(treasury_cap, tx_context::sender(ctx));
        transfer::freeze_object(
            XBTCInfo {
                id: object::new(ctx),
                name: utf8(b"XBTC"),
                symbol: utf8(b"XBTC"),
                decimals: 8
            }
        );
    }

    /// Mint XBTC to receiver
    /// Call by bridge
    public(friend) fun deposit(
        treasury_cap: &mut TreasuryCap<XBTC>,
        receiver: address,
        amount: u64,
        ctx: &mut TxContext
    ) {
        let coins_minted = coin::mint<XBTC>(treasury_cap, amount, ctx);
        transfer::transfer(coins_minted, receiver)
    }

    /// Join XBTC in `coins` with `self`
    /// The same as coin::join_vec
    /// Call by user
    public entry fun join_vec(
        self: &mut Coin<XBTC>,
        coins: vector<Coin<XBTC>>
    ) {
        let i = 0;
        let len = vector::length(&coins);
        while (i < len) {
            let coin = vector::remove(&mut coins, i);
            coin::join(self, coin);
            i = i + 1
        };
        // safe because we've drained the vector
        vector::destroy_empty(coins)
    }

    /// Send XBTC to receiver
    /// The same as coin::split_and_transfer
    /// Call by user
    public entry fun split_and_transfer(
        xbtc: &mut Coin<XBTC>,
        amount: u64,
        receiver: address,
        ctx: &mut TxContext
    ) {
        coin::split_and_transfer(
            xbtc,
            amount,
            receiver,
            ctx
        )
    }
}
