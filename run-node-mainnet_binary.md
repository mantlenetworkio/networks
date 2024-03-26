# Simple Mantle Node

**Tips: This tutorial is based on Mantle v1, if you want to use the latest Mantle v2, please refer to the [Mantle v2](https://github.com/mantlenetworkio/networks/blob/main/run-node-mainnetv2.md)**

## Required Software

- [golang 1.19 ]

## Recommended Hardware

- 16GB+ RAM
- 1000GB+ disk (HDD works for now, SSD is better)
- 10mb/s+ download

## Approximate Disk Usage

Usage as of 2022-09-21:

- Archive node: ~1000gb

## Installation and Setup Instructions

### build a binary file

```sh
git clone https://github.com/mantlenetworkio/mantle.git
cd mantle/l2geth
git checkout v0.4.3-5
make geth

```

### set up env and run

```sh
git clone https://github.com/mantlenetworkio/networks.git
cd networks
cd mainnet/envs
set -a
. ./geth.env
set +a
mkdir ~/mantle_l2geth_data
cd ../..
export ETH1_HTTP=https://rpc.ankr.com/eth
export SEQUENCER_CLIENT_HTTP=https://rpc.mantle.xyz
export ROLLUP_STATE_DUMP_PATH=https://mantlenetworkio.github.io/networks/mainnet/genesis.json
export ROLLUP_CLIENT_HTTP=https://dtl.mantle.xyz
export ROLLUP_BACKEND='l2'
export ETH1_CTC_DEPLOYMENT_HEIGHT=8
export RETRIES=60
export ROLLUP_VERIFIER_ENABLE='true'
export DATADIR=~/mantle_l2geth_data

cp ../mantle/l2geth/build/bin/geth .
export PATH=$PATH:$(pwd)
sh geth.sh
```

you need to change DATADIR to where you want to store data \
you need to change ETH1_HTTP to your own rpc

> note: if sync speed is slow , You could try to use https://dtl-us.mantle.xyz for US , https://dtl-eu.mantle.xyz/ for EU, https://dtl-ap.mantle.xyz/ for APAC . You could find this config in ./mainnet/envs/geth.env, the default value is : https://dtl.mantle.xyz .
