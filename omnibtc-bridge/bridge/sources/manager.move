/// Copyright 2022 OmniBTC Authors. Licensed under Apache-2.0 License.
module owner::manager {
    use std::string::utf8;
    use std::error;
    use aptos_framework::coin::{
        Self, BurnCapability, FreezeCapability, MintCapability
    };

    friend owner::bridge;

    const EMANAGER_CAPABILITIES: u64 = 1;

    /// Capabilities resource storing mint and burn capabilities.
    /// The resource is stored on the account that initialized coin `CoinType`.
    struct Capabilities<phantom CoinType> has key {
        burn_cap: BurnCapability<CoinType>,
        freeze_cap: FreezeCapability<CoinType>,
        mint_cap: MintCapability<CoinType>,
    }

    /// Issue a coin
    /// Call by admin of bridge
    public(friend) fun issue<CoinType>(
        account: &signer,
        name: vector<u8>,
        symbol: vector<u8>,
        decimals: u8,
    ) {
        let (burn_cap, freeze_cap, mint_cap) = coin::initialize<CoinType>(
            account,
            utf8(name),
            utf8(symbol),
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

    /// Call by admin of bridge
    public(friend) fun deposit<CoinType>(
        admin: address,
        receiver: address,
        amount: u64,
    ) acquires Capabilities {
        assert!(
            exists<Capabilities<CoinType>>(admin),
            error::not_found(EMANAGER_CAPABILITIES),
        );

        let capabilities = borrow_global<Capabilities<CoinType>>(admin);
        let coins_minted = coin::mint(amount, &capabilities.mint_cap);
        coin::deposit(receiver, coins_minted);
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
}

