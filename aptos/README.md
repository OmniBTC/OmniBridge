## bridge-aptos

## supported dependencies
- aptos-cli: `Aptos CLI Release v1.0.0`
- AptosFramework: `main @ 01108a2345b87d539d54a67b32db55193f9ace40`
- AptosStdlib: `main @ 01108a2345b87d539d54a67b32db55193f9ace40`

## roles and calls
- `owner`:
  - **publish** module: `xbtc.move`, `bridge.move`, `iterable_table.move`
  - **call** function: `bridge::initialize`
  
- `admin`:
  - **call** function: `bridge::{issue, deposit, set_min_withdraw}`
  
- `controller`:
  - **call** function: `bridge::set_pause`

- `user`: 
  - **call** function: `bridge::withdraw`, `xbtc::{register, transfer}`

## test cmds
```bash
# owner publish bridge
cd bridge
aptos move publish \
    --private-key=$PRIVATE \
    --url=http://127.0.0.1:8080 \
    --named-addresses owner=a24881e004fdbc5550932bb2879129351c21432f21f32d94bf11603bebd9f5c0

# owner bridge::initialize
aptos move run \
    --private-key=$PRIVATE \
    --url=http://127.0.0.1:8080 \
    --function-id=0xa24881e004fdbc5550932bb2879129351c21432f21f32d94bf11603bebd9f5c0::bridge::initialize \
    --args address:0xa24881e004fdbc5550932bb2879129351c21432f21f32d94bf11603bebd9f5c0 \
           address:0xa24881e004fdbc5550932bb2879129351c21432f21f32d94bf11603bebd9f5c0

# admin bridge::issue
aptos move run \
    --private-key=$PRIVATE \
    --url=http://127.0.0.1:8080 \
    --function-id=0xa24881e004fdbc5550932bb2879129351c21432f21f32d94bf11603bebd9f5c0::bridge::issue

# user xbtc::register
aptos move run \
    --private-key=$PRIVATE \
    --url=http://127.0.0.1:8080 \
    --function-id=0xa24881e004fdbc5550932bb2879129351c21432f21f32d94bf11603bebd9f5c0::xbtc::register

# admin bridge::deposit
aptos move run \
    --private-key=$PRIVATE \
    --url=http://127.0.0.1:8080 \
    --function-id=0xa24881e004fdbc5550932bb2879129351c21432f21f32d94bf11603bebd9f5c0::bridge::deposit \
    --args address:0xa24881e004fdbc5550932bb2879129351c21432f21f32d94bf11603bebd9f5c0 u64:10000000 string:"test" \

# user bridge::withdraw
aptos move run \
    --private-key=$PRIVATE \
    --url=http://127.0.0.1:8080 \
    --function-id=0xa24881e004fdbc5550932bb2879129351c21432f21f32d94bf11603bebd9f5c0::bridge::withdraw \
    --args u64:160000 string:"test"

# user xbtc::transfer
aptos move run \
    --private-key=$PRIVATE \
    --url=http://127.0.0.1:8080 \
    --function-id=0xa24881e004fdbc5550932bb2879129351c21432f21f32d94bf11603bebd9f5c0::xbtc::transfer  \
    --args address:0xa5dd9f5abfac2da1e0eb3f67e3d09ed97710358e03a6e73bd66f4444f176b975 u64:200000

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
