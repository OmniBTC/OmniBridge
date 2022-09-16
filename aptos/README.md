## aptos-bridge

## Roles and calls
- `owner`:
  - **publish** module: `manager.move`, `bridge.move`, `iterable_table.move`
  - **call** function: `bridge::initialize`
  
- `admin`:
  - **publish** module: `xbtc.move`
  - **call** function: `bridge::{issue,register_withdraw,deposit,set_min_withdraw}`
  
- `controller`:
  - **call** function: `bridge::set_pause`

- `user`: 
  - **call** function: `manager::{register, transfer}`, `bridge::withdraw`

## test cmds
```bash
# admin publish coins
cd coins
aptos move publish \
    --private-key=$PRIVATE \
    --url=http://127.0.0.1:8080 \
    --named-addresses admin=a24881e004fdbc5550932bb2879129351c21432f21f32d94bf11603bebd9f5c0

# owner publish bridge
cd bridge
aptos move publish \
    --private-key=$PRIVATE \
    --url=http://127.0.0.1:8080 \
    --named-addresses owner=a24881e004fdbc5550932bb2879129351c21432f21f32d94bf11603bebd9f5c0

# owner bridge::initialize
aptos move run \
    --private-key=$PRIVATE
    --url=http://127.0.0.1:8080 \
    --function-id=0xa24881e004fdbc5550932bb2879129351c21432f21f32d94bf11603bebd9f5c0::bridge::initialize \
    --args address:0xa24881e004fdbc5550932bb2879129351c21432f21f32d94bf11603bebd9f5c0 \
           address:0xa24881e004fdbc5550932bb2879129351c21432f21f32d94bf11603bebd9f5c0

# admin bridge::issue XBTC
aptos move run \
    --private-key=$PRIVATE \
    --url=http://127.0.0.1:8080 \
    --function-id=0xa24881e004fdbc5550932bb2879129351c21432f21f32d94bf11603bebd9f5c0::bridge::issue \
    --args string:"XBTC" string:"XBTC" u8:8 \
    --type-args 0xa24881e004fdbc5550932bb2879129351c21432f21f32d94bf11603bebd9f5c0::coins::XBTC

# admin bridge::register_withdraw XBTC
aptos move run \
    --private-key=$PRIVATE \
    --url=http://127.0.0.1:8080 \
    --function-id=0xa24881e004fdbc5550932bb2879129351c21432f21f32d94bf11603bebd9f5c0::bridge::register_withdraw \
    --type-args 0xa24881e004fdbc5550932bb2879129351c21432f21f32d94bf11603bebd9f5c0::coins::XBTC

# user manager::register
aptos move run \
    --private-key=$PRIVATE \
    --url=http://127.0.0.1:8080 \
    --function-id=0xa24881e004fdbc5550932bb2879129351c21432f21f32d94bf11603bebd9f5c0::manager::register \
    --type-args 0xa24881e004fdbc5550932bb2879129351c21432f21f32d94bf11603bebd9f5c0::coins::XBTC

# admin bridge::deposit
aptos move run \
    --private-key=`$PRIVATE` \
    --url=http://127.0.0.1:8080 \
    --function-id=0xa24881e004fdbc5550932bb2879129351c21432f21f32d94bf11603bebd9f5c0::bridge::deposit \
    --args address:0xa24881e004fdbc5550932bb2879129351c21432f21f32d94bf11603bebd9f5c0 u64:10000000 string:"test" \
    --type-args 0xa24881e004fdbc5550932bb2879129351c21432f21f32d94bf11603bebd9f5c0::coins::XBTC

# user bridge::withdraw
# aptos move run \
    --private-key=$PRIVATE \
    --url=http://127.0.0.1:8080 \
    --function-id=0xa24881e004fdbc5550932bb2879129351c21432f21f32d94bf11603bebd9f5c0::bridge::withdraw \
    --args u64:160000 string:"test"  \
    --type-args 0xa24881e004fdbc5550932bb2879129351c21432f21f32d94bf11603bebd9f5c0::coins::XBTC

# user manager::transfer
aptos move run \
    --private-key=$PRIVATE \
    --url=http://127.0.0.1:8080 \
    --function-id=0xa24881e004fdbc5550932bb2879129351c21432f21f32d94bf11603bebd9f5c0::manager::transfer  \
    --args address:0xa5dd9f5abfac2da1e0eb3f67e3d09ed97710358e03a6e73bd66f4444f176b975 u64:200000  \
    --type-args 0xa24881e004fdbc5550932bb2879129351c21432f21f32d94bf11603bebd9f5c0::coins::XBTC

# controller bridge::set_pause
aptos move run \
    --private-key=$PRIVATE   \
    --url=http://127.0.0.1:8080 \
    --function-id=0xa24881e004fdbc5550932bb2879129351c21432f21f32d94bf11603bebd9f5c0::bridge::set_pause \
    --args bool:true

# admin bridge::set_min_withdraw
aptos move run \
    --private-key=$PRIVATE   \
    --url=http://127.0.0.1:8080 \
    --function-id=0xa24881e004fdbc5550932bb2879129351c21432f21f32d94bf11603bebd9f5c0::bridge::set_min_withdraw \
    --args u64:10000000
```
