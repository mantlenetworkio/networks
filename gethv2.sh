#!/bin/sh

# start the geth node
echo "Starting Geth node"
exec geth --datadir=./data/mainnet-geth/ --verbosity=3 --port=30300 --http --http.corsdomain=* --http.vhosts=* --http.addr=0.0.0.0 --http.port=8545 --http.api=web3,eth,debug,txpool,net --ws --ws.addr=0.0.0.0 --ws.port=8546 --ws.origins=*  --ws.api=web3,eth,debug,txpool,net --syncmode=full  --maxpeers=0 --networkid=5000 --rpc.allow-unprotected-txs --authrpc.addr=0.0.0.0 --authrpc.port=8551 --authrpc.vhosts=* --authrpc.jwtsecret=./mainnet/secret/jwt_secret_txt --pprof --pprof.addr=0.0.0.0 --pprof.port=6060 --gcmode=full --metrics --metrics.addr=0.0.0.0  --metrics.port=9001 --snapshot=false --rollup.sequencerhttp=https://rpc.mantle.xyz

