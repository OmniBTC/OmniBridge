# OmniBridge

## OmniBridge: Solve the fully decentralized cross-chain between any chain.

## BTC-Move bridge:

A bridge between Bitcoin and Move language public chains (like Aptos and Sui) based on ultra-light node. 

### reference project： ChainX and ICP

their solution： BTC Light Node + Threshold Aggregate Signature + Smart Contract platform
For the BTC aggregate address to host BTC, only the addresses and accounts hosting BTC are decentralized enough to make BTC look as decentralized as POS. For example: Bind the aggregated custody account to the node account on the chain one by one, which is as decentralized as the POS chain.

There is still a problem with this way of thinking. Our OmniBTC wants to combine this solution of ChainX and the Lightning Network to be deployed on Aptos/Sui to provide Aptos/Sui with a fully decentralized BTC. It also allows BTC to carry the Move contract.

### OmniBTC solution:

BTC Light Node + Threshold Aggregate Signature + BTC Lightning Network + MoveVM
Lightning Network solves the mutual trust problem between Alice and Bob.
We just need to replace Alice with a BTC aggregate signature account (co-hosted by a sufficiently decentralized POS node on Aptos/Sui or a Dao administrator selected above).

### transition plan： 

Using BTC's L2 network ChainX as the BTC relay network, combined with the LayerZero message transmission protocol, send BTC to the MoveVM of the Aptos/Sui network, so that the mirror network asset XBTC can have the ability to program in the Move language。

[The interactive interface PR between ChainX network and Aptos/Sui](https://github.com/chainx-org/ChainX/commit/d62ce2e9eb0dbcafb3251c4fa459c95fd1e6a17f)

## EVM-Move bridge：

A decentralized bridge between the POS version of the EVM chain (such as ethereum, BSC) and the Move language public chain(like Aptos and Sui).

## [Details](https://github.com/OmniBTC/OmniBridge/blob/main/BTC_bridge_solution.md)
