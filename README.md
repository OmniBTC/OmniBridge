# OmniBridge

## OmniBridge: Solve the fully decentralized cross-chain between any chain.

## BTC-Move bridge:

A bridge between Bitcoin and Move language public chains (like Aptos and Sui) based on ultra-light node. [Details](https://github.com/OmniBTC/OmniBridge/blob/main/BTC_bridge_solution.md)

reference project： ChainX and ICP
their solution： BTC Light Node + Threshold Aggregate Signature + Smart Contract platform
For the BTC aggregate address to host BTC, only the addresses and accounts hosting BTC are decentralized enough to make BTC look as decentralized as POS. For example: Bind the aggregated custody account to the node account on the chain one by one, which is as decentralized as the POS chain.

There is still a problem with this way of thinking. Our OmniBTC wants to combine this solution of ChainX and the Lightning Network to be deployed on Sui to provide Sui with a fully decentralized BTC. It also allows BTC to carry the Move contract.

OmniBTC solution:
BTC Light Node + Threshold Aggregate Signature + BTC Lightning Network + MoveVM
Lightning Network solves the mutual trust problem between Alice and Bob.
We just need to replace Alice with a BTC aggregate signature account (co-hosted by a sufficiently decentralized POS node on Sui or a Dao administrator selected above).

## EVM-Move bridge：

A decentralized bridge between the POS version of the EVM chain (such as ethereum, BSC) and the Move language public chain(like Aptos and Sui).
