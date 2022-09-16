/// Copyright 2022 OmniBTC Authors. Licensed under Apache-2.0 License.
module owner::xbtc {
    use std::string::utf8;
    use aptos_framework::coin::{
        Self, BurnCapability, FreezeCapability, MintCapability
    };

    friend owner::bridge;

    /// XBTC define
    ////////////////////////
    struct XBTC {}
    ////////////////////////

    /// Capabilities resource storing mint and burn capabilities.
    /// The resource is stored on the account that initialized coin `CoinType`.
    struct Capabilities has key {
        burn_cap: BurnCapability<XBTC>,
        freeze_cap: FreezeCapability<XBTC>,
        mint_cap: MintCapability<XBTC>,
    }

    /// A helper function
    public fun has_capabilities(
        account: address
    ):bool {
        exists<Capabilities>(account)
    }

    /// Issue XBTC
    /// Call by bridge
    public(friend) fun issue(
        account: &signer,
    ) {
        let (burn_cap, freeze_cap, mint_cap) = coin::initialize<XBTC>(
            account,
            utf8(b"XBTC"),
            utf8(b"XBTC"),
            8,
            true, // always monitor supply
        );

        move_to(
            account,
            Capabilities {
                burn_cap,
                freeze_cap,
                mint_cap,
            }
        );
    }

    /// Mint XBTC to receiver
    /// Call by bridge
    public(friend) fun deposit(
        admin: address,
        receiver: address,
        amount: u64,
    ) acquires Capabilities {
        let capabilities = borrow_global<Capabilities>(admin);
        let coins_minted = coin::mint(amount, &capabilities.mint_cap);
        coin::deposit(receiver, coins_minted);
    }

    /// Register XBTC account
    /// The same as 0x1::manged_coin::register
    /// Call by user
    public entry fun register(
        account: &signer
    ) {
        coin::register<XBTC>(account);
    }

    /// Transfer XBTC
    /// The same as 0x1::coin::transfer
    /// Call by user
    public entry fun transfer(
        sender: &signer,
        receiver: address,
        amount: u64,
    ){
        coin::transfer<XBTC>(sender, receiver, amount)
    }
}

