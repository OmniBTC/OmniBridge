## bridge-sui

## supported dependencies
- sui-cli: `sui 0.9.0`
- Sui: `devnet-0.9.0 @ df05544fb0cbd6d6db016e71e5facb5e7cc27988`

## roles and calls
- `owner`:
    - **publish** module: `xbtc.move`, `bridge.move`, `vec_queue.move`
    - **call** function: `bridge::initialize`

- `admin`:
    - **call** function: `bridge::{deposit, set_min_withdraw}`

- `controller`:
    - **call** function: `bridge::set_pause`

- `user`:
    - **call** function: `bridge::withdraw`, `xbtc::{join_vec, split_and_transfer}`

## test cmds
```bash
# temp local testnet
sui-test-validator
curl -H "Content-Type: application/json" \
     -X POST \
     -d '{"recipient":"0xdea83a5c27ef936cd9efd3bc596696e1d101d647"}' \
     "http://127.0.0.1:9123/faucet"

# owner publish bridge
cd bridge
sui client publish --gas-budget 10000

# flow the above result
export package_id=0xc087a76e0495c395db814587688930b7fd808cad
export treasury_cap=0x5c3d9503d9963c0887b13e6b1cca4c9ca341d39d
export bridge_info=0xe57396fb7f2c09ffb0fec0af7e175d106dc18253

# owner bridge::initialize
sui client call --gas-budget 10000 \
    --package $package_id \
    --module "bridge" \
    --function "initialize" \
    --args $bridge_info \
           $treasury_cap \
           0xdea83a5c27ef936cd9efd3bc596696e1d101d647 \
           0xdea83a5c27ef936cd9efd3bc596696e1d101d647
           
# admin bridge::deposit
sui client call --gas-budget 10000 \
    --package $package_id \
    --module "bridge" \
    --function "deposit" \
    --args $bridge_info \
           $treasury_cap \
           0xdea83a5c27ef936cd9efd3bc596696e1d101d647 \
           100000 \
           "test"
           
# admin bridge::set_min_withdraw
sui client call --gas-budget 10000 \
    --package $package_id \
    --module "bridge" \
    --function "set_min_withdraw" \
    --args $bridge_info 1000

sui client objects

# user bridge::withdraw
# cherry-pick coin<XBTC> 0x75da7659b8036a5e0ae8d8c49fe6a497b7e2cd68
sui client call --gas-budget 10000 \
    --package $package_id \
    --module "bridge" \
    --function "withdraw" \
    --args $bridge_info \
           0x75da7659b8036a5e0ae8d8c49fe6a497b7e2cd68 \
           1000 \
           "test"

# controller bridge::set_pause
sui client call --gas-budget 10000 \
    --package $package_id \
    --module "bridge" \
    --function "set_pause" \
    --args $bridge_info false
    
sui client objects

# user xbtc::split_and_transfer
# cherry-pick coin<XBTC> 0x75da7659b8036a5e0ae8d8c49fe6a497b7e2cd68
sui client call --gas-budget 10000  \
    --package $package_id \
    --module "xbtc"  \
    --function "split_and_transfer" \
    --args 0x75da7659b8036a5e0ae8d8c49fe6a497b7e2cd68 \
           100 \
           0xdea83a5c27ef936cd9efd3bc596696e1d101d647

sui client objects

# user xbtc::join
# cherry-pick coin<XBTC> 0x75da7659b8036a5e0ae8d8c49fe6a497b7e2cd68
# cherry-pick coin<XBTC> 0x21fc2493552578665ce3f9bc9a671936ae4e0d81
sui client call --gas-budget 10000  \
    --package $package_id \
    --module "xbtc"  \
    --function "join" \
    --args 0x75da7659b8036a5e0ae8d8c49fe6a497b7e2cd68 \
           0x21fc2493552578665ce3f9bc9a671936ae4e0d81

sui client objects
```
