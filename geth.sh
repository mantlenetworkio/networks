#!/bin/sh

# FIXME: Cannot use set -e since bash is not installed in Dockerfile
# set -e

RETRIES=${RETRIES:-40}
VERBOSITY=${VERBOSITY:-6}

# get the genesis file from the deployer
curl \
    --fail \
    --show-error \
    --silent \
    --retry-connrefused \
    --retry-all-errors \
    --retry $RETRIES \
    --retry-delay 5 \
    $ROLLUP_STATE_DUMP_PATH \
    -o genesis.json

# wait for the dtl to be up, else geth will crash if it cannot connect
curl \
    --fail \
    --show-error \
    --silent \
    --output /dev/null \
    --retry-connrefused \
    --retry $RETRIES \
    --retry-delay 1 \
    $ROLLUP_CLIENT_HTTP

# import the key that will be used to locally sign blocks
# this key does not have to be kept secret in order to be secure
# we use an insecure password ("pwd") to lock/unlock the password
echo "Importing private key"
echo $BLOCK_SIGNER_KEY > key.prv
echo "pwd" > password
geth account import --password ./password ./key.prv
echo $FP_OPERATOR_PRIVATE_KEY > key.prv
geth account import --password ./password ./key.prv

# initialize the geth node with the genesis file
echo "Initializing Geth node"
geth --verbosity="$VERBOSITY" "$@" init genesis.json

# start the geth node

export ETH1_HTTP=https://rpc.ankr.com/eth
export SEQUENCER_CLIENT_HTTP=https://rpc.mantle.xyz
export ROLLUP_TIMESTAMP_REFRESH=5s
export ROLLUP_STATE_DUMP_PATH=https://mantlenetworkio.github.io/networks/mainnet/genesis.json
export ROLLUP_CLIENT_HTTP=https://dtl.mantle.xyz
export ETH1_CTC_DEPLOYMENT_HEIGHT="17577586"
export RETRIES="60"
export ROLLUP_ENFORCE_FEES=true
export ROLLUP_FEE_THRESHOLD_DOWN="1"
export ROLLUP_FEE_THRESHOLD_UP="4000"
export GASPRICE="0"
export ETH1_SYNC_SERVICE_ENABLE=true
export ETH1_CONFIRMATION_DEPTH="0"
export ROLLUP_POLL_INTERVAL_FLAG=500ms
export ROLLUP_ENABLE_L2_GAS_POLLING=true
export ROLLUP_BACKEND='l2'
export ROLLUP_VERIFIER_ENABLE='true'
export RPC_ENABLE=true
export RPC_ADDR=0.0.0.0
export RPC_PORT="8545"
export RPC_API=eth,net,rollup,web3
export RPC_CORS_DOMAIN='*'
export RPC_VHOSTS='*'
export WS=true
export WS_ADDR=0.0.0.0
export WS_PORT="8546"
export WS_API=eth,net,rollup,web3
export WS_ORIGINS='*'
export CHAIN_ID="5000"
export DATADIR=/home/ubuntu/git/mantle/ops/scripts/data_jeremy
export GCMODE=archive
export IPC_DISABLE=true
export NETWORK_ID="5000"
export NO_USB=true
export NO_DISCOVER=true
export TARGET_GAS_LIMIT="30000000"
export USING_BVM=true
export VERBOSITY="3"
export BLOCK_SIGNER_KEY=9f50ccaebd966113a0ef09793f8a3288cd0bb2c05d20caa3c0015b4e665f1b2d
export BLOCK_SIGNER_ADDRESS=0x000000b36A00872bAF079426e012Cf5Cd2A74E8b
export ETH1_HTTP=https://rpc.ankr.com/eth
export SEQUENCER_CLIENT_HTTP=https://rpc.mantle.xyz
export ROLLUP_STATE_DUMP_PATH=https://mantlenetworkio.github.io/networks/mainnet/genesis.json
export ROLLUP_CLIENT_HTTP=https://dtl.mantle.xyz
export ROLLUP_BACKEND='l2'
export ETH1_CTC_DEPLOYMENT_HEIGHT=8
export RETRIES=60
export ROLLUP_VERIFIER_ENABLE='true'

echo "Starting Geth node"
exec geth \
  --verbosity="$VERBOSITY" \
  --password ./password \
  --allow-insecure-unlock \
  --unlock $BLOCK_SIGNER_ADDRESS \
  --mine \
  --miner.etherbase $BLOCK_SIGNER_ADDRESS \
  "$@"
