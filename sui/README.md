## bridge-sui

## supported dependencies
- sui-cli: `sui 0.9.0`
- Sui: `devnet-0.9.0 @ df05544fb0cbd6d6db016e71e5facb5e7cc27988`

## Roles and calls
- `owner`:
    - **publish** module: `xbtc.move`, `bridge.move`, `vec_queue.move`
    - **call** function: `bridge::initialize`

- `admin`:
    - **call** function: `bridge::{deposit, set_min_withdraw}`

- `controller`:
    - **call** function: `bridge::set_pause`

- `user`:
    - **call** function: `bridge::withdraw`, `xbtc::{join_vec, split_and_transfer}`
