# Simple Mantle Node (Sepolia Testnet)

## Recommended Hardware

- 16GB+ RAM
- 8C+ CPU
- 1000GB+ disk (HDD works for now, SSD is better)
- 10mb/s+ download

You can run a Mantle Sepolia RPC node either with **Docker Compose** (simplest,
single host) or with the bundled **Helm chart** on Kubernetes.

> **Note (v1.5.3 upgrade):** When upgrading, you must ensure that
> **mantle-op-geth starts before mantle-op-node**. Failure to follow this
> order may cause a chain fork. If a fork occurs, rebuild the RPC node by
> following the full setup instructions in this document.

---

# 1. Deploy with Docker Compose

## Required Software

- [docker](https://docs.docker.com/engine/install/)
- [node](https://nodejs.org/en/download/)
- [foundry](https://github.com/foundry-rs/foundry/releases)
- [zstd](https://github.com/facebook/zstd)
- [aira2](https://aria2.github.io/)

## Installation

### 1 Download repo

```
git clone https://github.com/mantle-xyz/networks.git
```

### 2 Generate init file

generate the 'jwt\_secret\_txt' file and the 'p2p\_node\_key\_txt'

```
cd networks/

mkdir sepolia/secret

node -e "console.log(require('crypto').randomBytes(32).toString('hex'))" > sepolia/secret/jwt_secret_txt

cast w n |grep -i "Private Key" |awk -F ": " '{print $2}' |sed 's/0x//' > sepolia/secret/p2p_node_key_txt
```

### 3 Download the latest snapshot from mantle

We recommend that you start the node with latest shapshot, so that you don't need to wait a long time to sync data.

First, create a path for ledger:

```
mkdir -p ./data/sepolia-geth
```

Second, download the latest official snapshot:

```
# Download tarball
SEPOLIA_CURRENT_TARBALL_DATE=`curl https://s3.ap-southeast-1.amazonaws.com/snapshot.sepolia.mantle.xyz/current.info`
wget -c https://s3.ap-southeast-1.amazonaws.com/snapshot.sepolia.mantle.xyz/${SEPOLIA_CURRENT_TARBALL_DATE}-sepolia-chaindata.tar.zst

# Then you can verify your download
SEPOLIA_CURRENT_TARBALL_CHECKSUM=`curl https://s3.ap-southeast-1.amazonaws.com/snapshot.sepolia.mantle.xyz/${SEPOLIA_CURRENT_TARBALL_DATE}-sepolia-chaindata.tar.zst.sha256sum | awk '{print $1}'`
echo "${SEPOLIA_CURRENT_TARBALL_CHECKSUM} *${SEPOLIA_CURRENT_TARBALL_DATE}-sepolia-chaindata.tar.zst" | shasum -a 256 --check

# You should get the following output:
# ${SEPOLIA_CURRENT_TARBALL_DATE}-sepolia-chaindata.tar.zst: OK
```

Third, unzip snapshot to the ledger path

```
tar --use-compress-program=unzstd -xvf ${SEPOLIA_CURRENT_TARBALL_DATE}-sepolia-chaindata.tar.zst -C  ./data/sepolia-geth
```

Check the data was unarchived successfully:

```
$ ls ./data/sepolia-geth
chaindata
```

### 4 Operating the Node

use L1 beacon chain to pull the data for rollup node,
you need set up L1\_BEACON\_SEPOLIA and L1\_RPC\_SEPOLIA

L1\_BEACON\_SEPOLIA is for querying data from eth blob, or you can use mantle da-indexer instead.

```
export L1_RPC_SEPOLIA='https://rpc.ankr.com/eth_sepolia'        #please replace
export L1_BEACON_SEPOLIA='https://eth-beacon-chain-sepolia.drpc.org/rest/'  #please replace
# alternatively use the mantle da-indexer:
# docker-compose -f docker-compose-sepolia-upgrade-da-indexer.yml up -d

docker-compose -f docker-compose-sepolia-upgrade-beacon.yml up -d
```

## Check Installation Result

Follow these steps to check if the installation is successful

### 1 Check Service

If the service status is 'up,' it means that the service has started without any issues.

```
docker-compose -f docker-compose-sepolia-upgrade-beacon.yml ps
```

### 2 Check Data

```
# query local op-geth latest block height
cast bn

# query latest block height from mantle sepolia rpc
cast bn --rpc-url  https://rpc.sepolia.mantle.xyz

# check the safe and finalized height.
cast rpc optimism_syncStatus --rpc-url localhost:9545 |jq .safe_l2.number
cast rpc optimism_syncStatus --rpc-url localhost:9545 |jq .finalized_l2.number
```

## Upgrade for historical user

### 1 Stop historical node

```
docker-compose -f docker-compose-sepolia-upgrade-beacon.yml down
```

### 2 Pull the latest code of this repo

```
# If your local code have changes, please use 'git stash' to cache first

git pull
```

**If you start the node using your own way, please refer to the compose files in this repo for the upgrade. Otherwise, it may cause irreversible damage to the node.**

### 3 Operating the Node

```
export L1_RPC_SEPOLIA='https://rpc.ankr.com/eth_sepolia'        #please replace
export L1_BEACON_SEPOLIA='https://eth-beacon-chain-sepolia.drpc.org/rest/'  #please replace
docker-compose -f docker-compose-sepolia-upgrade-beacon.yml up -d
```

### 4 Check data

```
# query local op-geth latest block height and mantle sepolia rpc
cast bn && cast bn --rpc-url  https://rpc.sepolia.mantle.xyz

# check the safe and finalized height.
cast rpc optimism_syncStatus --rpc-url localhost:9545 |jq .safe_l2.number
cast rpc optimism_syncStatus --rpc-url localhost:9545 |jq .finalized_l2.number
```

---

# 2. Deploy on Kubernetes with Helm

This repo also ships a Helm chart at [`chart/mantle-node`](chart/mantle-node/).
It deploys two `StatefulSet`s (the `op-geth` execution layer and `op-node`),
provisions PVCs for chain data and peerstore, and mounts `rollup.json`
straight from this repo via a `ConfigMap`. You supply the engine-API JWT
and op-node libp2p key in the per-network values file. The official
snapshot from S3 is fetched + extracted by an init container on first
boot.

## Required Software

- [helm](https://helm.sh/docs/intro/install/) 3.8+
- [kubectl](https://kubernetes.io/docs/tasks/tools/) pointed at a cluster
  with a default `StorageClass` (override with
  `--set el.persistence.storageClass=...` if needed)
- [node](https://nodejs.org/en/download/) (for generating the JWT secret)
- [foundry](https://github.com/foundry-rs/foundry/releases) (for `cast` —
  generates the p2p key and queries the node)

## Installation

### 1 Download repo

```
git clone https://github.com/mantle-xyz/networks.git
cd networks
```

### 2 Generate init file

generate the 'jwt\_secret\_txt' value and the 'p2p\_node\_key\_txt' value
(same commands as the Docker path, just printed to stdout so you can paste
them into the values file below):

```
node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"

cast w n |grep -i "Private Key" |awk -F ": " '{print $2}' |sed 's/0x//'
```

### 3 Edit sepolia.values.yaml

Open `chart/mantle-node/sepolia.values.yaml` and fill in your L1 endpoints
and the two secrets you just generated:

```yaml
l1:
  rpc:    "SEPOLIA_L1_RPC"        # please replace
  beacon: "SEPOLIA_L1_BEACON"     # please replace

secrets:
  jwtSecret:   "<paste the jwt_secret_txt value here>"
  p2pNodeKey:  "<paste the p2p_node_key_txt value here>"
```

### 4 Install

```
helm install sepolia ./chart/mantle-node \
  -f ./chart/mantle-node/sepolia.values.yaml \
  --namespace mantle-sepolia --create-namespace
```

On first install, the chart automatically downloads + extracts the latest
official Mantle Sepolia snapshot from S3
(`https://s3.ap-southeast-1.amazonaws.com/snapshot.sepolia.mantle.xyz`)
into the EL PVC. The init container is a no-op when the PVC already
contains chain data, so it is safe across `helm upgrade`.

Watch snapshot progress with:

```
kubectl -n mantle-sepolia logs -f sts/sepolia-mantle-node-el -c fetch-snapshot
```

## Check Installation Result

```
kubectl -n mantle-sepolia get pods -w
kubectl -n mantle-sepolia logs -f sts/sepolia-mantle-node-el
kubectl -n mantle-sepolia logs -f sts/sepolia-mantle-node-op-node

# Query block height
kubectl -n mantle-sepolia port-forward svc/sepolia-mantle-node-el 8545:8545 &
cast bn

# Compare against the official Mantle sepolia RPC
cast bn --rpc-url https://rpc.sepolia.mantle.xyz

# Sync status from op-node
kubectl -n mantle-sepolia port-forward svc/sepolia-mantle-node-op-node 9545:8545 &
cast rpc optimism_syncStatus --rpc-url localhost:9545 | jq .safe_l2.number
cast rpc optimism_syncStatus --rpc-url localhost:9545 | jq .finalized_l2.number
```

## Upgrade

```
git pull
helm upgrade sepolia ./chart/mantle-node \
  -f ./chart/mantle-node/sepolia.values.yaml \
  --namespace mantle-sepolia
```

See [`chart/mantle-node/README.md`](chart/mantle-node/README.md) for the
full list of values and the same-chart presets for Hoodi and Mainnet
(`hoodi.values.yaml`, `mainnet.values.yaml`).
