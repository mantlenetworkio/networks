# Simple Mantle Node (Hoodi Testnet)

## Required Software

- [docker](https://docs.docker.com/engine/install/)
- [node](https://nodejs.org/en/download/)
- [foundry](https://github.com/foundry-rs/foundry/releases)
- [zstd](https://github.com/facebook/zstd)
- [aira2](https://aria2.github.io/)

## Recommended Hardware

- 8GB+ RAM
- 4C+ CPU
- 100GB+ disk (HDD works for now, SSD is better)
- 10mb/s+ download

# Installation and Setup Instructions For New User

## Installation

### 1 Download repo

```
git clone https://github.com/mantlenetworkio/networks.git
```

### 2 Generate init file

generate the 'jwt\_secret\_txt' file and the 'p2p\_node\_key\_txt'

```
cd networks/

mkdir hoodi/secret

node -e "console.log(require('crypto').randomBytes(32).toString('hex'))" > hoodi/secret/jwt_secret_txt

cast w n |grep -i "Private Key" |awk -F ": " '{print $2}' |sed 's/0x//' > hoodi/secret/p2p_node_key_txt
```

### 3 Download the latest snapshot from mantle

We recommend that you start the node with latest shapshot, so that you don't need to wait a long time to sync data.

First, create a path for ledger:

```
mkdir -p ./data/hoodi-reth
```

Second, download the latest official snapshot:

```
# Download tarball
HOODI_CURRENT_TARBALL_DATE=`curl https://s3.ap-southeast-1.amazonaws.com/snapshot.hoodi.mantle.xyz/current.info`
wget -c https://s3.ap-southeast-1.amazonaws.com/snapshot.hoodi.mantle.xyz/${HOODI_CURRENT_TARBALL_DATE}-hoodi.tar.zst

# Then you can verify your download
HOODI_CURRENT_TARBALL_CHECKSUM=`curl https://s3.ap-southeast-1.amazonaws.com/snapshot.hoodi.mantle.xyz/${HOODI_CURRENT_TARBALL_DATE}-hoodi-chaindata.tar.zst.sha256sum | awk '{print $1}'`
echo "${HOODI_CURRENT_TARBALL_CHECKSUM} *${HOODI_CURRENT_TARBALL_DATE}-hoodi.tar.zst" | shasum -a 256 --check

# You should get the following output:
# ${HOODI_CURRENT_TARBALL_DATE}-hoodi.tar.zst: OK
```

Third, unzip snapshot to the ledger path

```
tar --use-compress-program=unzstd -xvf ${HOODI_CURRENT_TARBALL_DATE}-hoodi.tar.zst -C  ./data/hoodi-reth
```

Check the data was unarchived successfully:

```
$ ls ./data/hoodi-reth
blobstore  db  discovery-secret  genesis.json  invalid_block_hooks  known-peers.json  lost+found  reth.toml  static_files 
```

### 4 Operating the Node

use L1 beacon chain to pull the data for rollup node,
you need set up L1\_BEACON\_HOODI and L1\_RPC\_HOODI

L1\_BEACON\_HOODI is for querying data from eth blob,or you can use mantle da-indexer instead.the da-indexer address is <https://da-indexer-api.hoodi.mantle.xyz>

```
export L1_RPC_HOODI='HOODI_L1_RPC'        #please replace
export L1_BEACON_HOODI='HOODI_L1_BEACON'  #please replace
# export L1_BEACON_HOODI='https://da-indexer-api.hoodi.mantle.xyz'  #if you want to use mantle da-indexer.

docker-compose -f docker-compose-hoodi-upgrade.yml up -d 
```

## Check Installation Result

Follow these steps to check if the installation is successful

### 1 Check Service

If the service status is 'up,' it means that the service has started without any issues.

```
docker-compose -f docker-compose-hoodi-upgrade.yml ps
```

### 2 Check Data

```
# query local op-reth latest block height
cast bn

# query latest block height from mantle hoodi rpc
cast bn --rpc-url  https://rpc.hoodi.mantle.xyz

# check the safe and finalized height. 
cast rpc optimism_syncStatus --rpc-url localhost:9545 |jq .safe_l2.number
cast rpc optimism_syncStatus --rpc-url localhost:9545 |jq .finalized_l2.number
```

# Deploy on Kubernetes with Helm

If you'd rather run the node on Kubernetes than via `docker-compose`, this
repo ships a Helm chart at [`chart/mantle-node`](chart/mantle-node/). It
deploys two `StatefulSet`s (the `op-reth` execution client and `op-node`),
provisions PVCs for chain data and peerstore, auto-generates the JWT secret
and op-node libp2p key, and fetches `genesis.json` / `rollup.json` via an
init container.

## Prerequisites

- Kubernetes 1.23+ with a default `StorageClass` (override with
  `--set l2.persistence.storageClass=...` if needed)
- Helm 3.8+
- Same L1 RPC / L1 beacon endpoints as the docker-compose path

## Install

```
git clone https://github.com/mantlenetworkio/networks.git
cd networks
```

Edit `chart/mantle-node/hoodi.values.yaml` and fill in your L1 endpoints:

```yaml
l1:
  rpc:    "HOODI_L1_RPC"        # please replace
  beacon: "HOODI_L1_BEACON"     # please replace
  # beacon: "https://da-indexer-api.hoodi.mantle.xyz"  # or use Mantle DA indexer
```

Then install:

```
helm install hoodi ./chart/mantle-node \
  -f ./chart/mantle-node/hoodi.values.yaml \
  --namespace mantle-hoodi --create-namespace
```

## Snapshot bootstrap

On first install the chart automatically downloads + extracts the latest
official Mantle Hoodi snapshot from S3
(`https://s3.ap-southeast-1.amazonaws.com/snapshot.hoodi.mantle.xyz`) into
the L2 PVC. No flag is required. The init container is a no-op when the
PVC already contains chain data, so it is safe across `helm upgrade`.

Watch progress with:

```
kubectl -n mantle-hoodi logs -f sts/hoodi-mantle-node-l2 -c fetch-snapshot
```

## Verify

```
kubectl -n mantle-hoodi get pods -w
kubectl -n mantle-hoodi logs -f sts/hoodi-mantle-node-l2
kubectl -n mantle-hoodi logs -f sts/hoodi-mantle-node-op-node

# Query block height
kubectl -n mantle-hoodi port-forward svc/hoodi-mantle-node-l2 8545:8545 &
cast bn

# Compare against the official Mantle hoodi RPC
cast bn --rpc-url https://rpc.hoodi.mantle.xyz

# Sync status from op-node
kubectl -n mantle-hoodi port-forward svc/hoodi-mantle-node-op-node 9545:8545 &
cast rpc optimism_syncStatus --rpc-url localhost:9545 | jq .safe_l2.number
cast rpc optimism_syncStatus --rpc-url localhost:9545 | jq .finalized_l2.number
```

## Upgrade

```
git pull
helm upgrade hoodi ./chart/mantle-node \
  -f ./chart/mantle-node/hoodi.values.yaml \
  --namespace mantle-hoodi
```

See [`chart/mantle-node/README.md`](chart/mantle-node/README.md) for the
full list of values and the same-chart presets for Sepolia and Mainnet
(`sepolia.values.yaml`, `mainnet.values.yaml`).

# Upgrade for historical user

## 1 Stop historical node

```
docker-compose -f docker-compose-hoodi-upgrade.yml down
```

## 2 Pull the latest code of this repo

```
# If your local code have changes, please use 'git stash' to cache first

git pull 
```

**If you start the node using your own way, please refer to the compose files in this repo for the upgrade. Otherwise, it may cause irreversible damage to the node.**

## 3 Operating the Node

```
export L1_RPC_HOODI='HOODI_L1_RPC'        #please replace
export L1_BEACON_HOODI='HOODI_L1_BEACON'  #please replace
docker-compose -f docker-compose-hoodi-upgrade.yml up -d 
```

## 4 Check data

```
# query local op-reth latest block height and mantle hoodi rpc
cast bn && cast bn --rpc-url  https://rpc.hoodi.mantle.xyz

# check the safe and finalized height. 
cast rpc optimism_syncStatus --rpc-url localhost:9545 |jq .safe_l2.number
cast rpc optimism_syncStatus --rpc-url localhost:9545 |jq .finalized_l2.number
```

