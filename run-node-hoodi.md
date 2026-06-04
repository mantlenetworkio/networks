# Simple Mantle Node (Hoodi Testnet)

## Required Software

* [docker](https://docs.docker.com/engine/install/)
* [node](https://nodejs.org/en/download/)
* [foundry](https://github.com/foundry-rs/foundry/releases)
* [zstd](https://github.com/facebook/zstd)
* [aira2](https://aria2.github.io/)

## Recommended Hardware

* 16GB+ RAM

* 8C+ CPU

* 100GB+ disk (HDD works for now, SSD is better)

* 10mb/s+ download

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

#### 4.1 Start with mantle da-indexer

use mantle da-indexer to pull the data for rollup node, and you need to set up L1_RPC_HOODI


```
export L1_RPC_HOODI='TODO_HOODI_L1_RPC'  #please replace, e.g. https://0xrpc.io/hoodi
docker-compose -f docker-compose-hoodi-upgrade-da-indexer.yml up -d 
```

Will start the node in a detached shell (`-d`), meaning the node will continue to run in the background. You will need to run this again if you ever turn your machine off.

Congratulations, the node has been deployed！

#### 4.2 Start with L1 beacon chain（recommend）

use L1 beacon chain to pull the data for rollup node, 
you need set up L1_BEACON_HOODI and L1_RPC_HOODI 

L1_BEACON_HOODI is for querying data from eth blob

```
export L1_RPC_HOODI='TODO_HOODI_L1_RPC'        #please replace
export L1_BEACON_HOODI='TODO_HOODI_L1_BEACON'  #please replace

docker-compose -f docker-compose-hoodi-upgrade-beacon.yml up -d 
```

## Check Installation Result

Follow these steps to check if the installation is successful

### 1 Check Service

If the service status is 'up,' it means that the service has started without any issues.

```
docker-compose -f docker-compose-hoodi-upgrade-beacon.yml ps
```

### 2 Check Data

Use the command 'cast bn' to execute multiple times and check if the height increases.

example:

```
# query local op-geth latest block height
cast bn

# query latest block height from mantle hoodi rpc
cast bn --rpc-url  TODO_HOODI_SEQUENCER_URL
```

Use the command 'cast rpc optimism_syncStatus' to execute multiple times and check if the safe\_l2 and inalized\_l2 increases. It may need to be increased after thirty minutes

example:

```
cast rpc optimism_syncStatus --rpc-url localhost:9545 |jq .finalized_l2.number

cast rpc optimism_syncStatus --rpc-url localhost:9545 |jq .safe_l2.number
```



## Other useful commands for Operator

### 1 Stop

```
docker-compose -f docker-compose-hoodi-upgrade-beacon.yml down
```

Will shut down the node without wiping any volumes. You can safely run this command and then restart the node again.

### 2 Wipe

```
docker-compose -f docker-compose-hoodi-upgrade-beacon.yml down -v
```

Will completely wipe the node by removing the volumes that were created for each container. Note that this is a destructive action, be very careful!

### 3 Logs

```
docker-compose logs <service name>
```

Will display the logs for a given service. You can also follow along with the logs for a service in real time by adding the flag `-f`.

The available services are:

* `op-geth`

* `op-node`


# Upgrade for historical user
> **Note:** When upgrading, please follow the correct update order: update **mantle-op-geth** first, then update **mantle-op-node**. Reversing this order may cause unexpected issues.

## 1 Stop historical node

```
docker-compose -f docker-compose-hoodi-upgrade-beacon.yml down
docker-compose -f docker-compose-hoodi-upgrade-da-indexer.yml down
```

## 2 Pull the latest code of this repo

```
# If your local code have changes, please use 'git stash' to cache first

git pull 
```

**If you start the node using your own way, please refer to the compose files in this repo for the upgrade. Otherwise, it may cause irreversible damage to the node.**

## 3 Operating the Node

### 3.1 start with mantle da-indexer


```
export L1_RPC_HOODI='TODO_HOODI_L1_RPC'  #please replace
docker-compose -f docker-compose-hoodi-upgrade-da-indexer.yml up -d 
```

### 3.2 start with L1 beacon chain（recommend）

use L1 beacon chain to pull the data for rollup node

you need to edit L1_BEACON_HOODI and L1_RPC_HOODI 

L1_BEACON_HOODI is for querying data from eth blob


then start with

```
export L1_RPC_HOODI='TODO_HOODI_L1_RPC'        #please replace
export L1_BEACON_HOODI='TODO_HOODI_L1_BEACON'  #please replace
docker-compose -f docker-compose-hoodi-upgrade-beacon.yml up -d 
```

## 4 Check data

Use the command 'cast bn' to execute multiple times and check if the height increases.

example:

```
# query local op-geth latest block height
cast bn

# query latest block height from mantle hoodi rpc
cast bn --rpc-url  TODO_HOODI_SEQUENCER_URL
```

Use the command 'cast rpc optimism_syncStatus' to execute multiple times and check if the safe\_l2 and inalized\_l2 increases. It may need to be increased after thirty minutes

example:

```
cast rpc optimism_syncStatus --rpc-url localhost:9545 |jq .finalized_l2.number

cast rpc optimism_syncStatus --rpc-url localhost:9545 |jq .safe_l2.number
```

# Restore from snapshot

If your node's data is corrupted due to abnormal operations, please refer to the following steps for recovery

## 1 Clean up historical data

```
rm -fr ./data/hoodi-geth 
```

## 2 Download the latest data

```
mkdir -p ./data/hoodi-geth

# download the latest official snapshot
HOODI_CURRENT_TARBALL_DATE=`curl https://s3.ap-southeast-1.amazonaws.com/snapshot.hoodi.mantle.xyz/current.info`
wget -c https://s3.ap-southeast-1.amazonaws.com/snapshot.hoodi.mantle.xyz/${HOODI_CURRENT_TARBALL_DATE}-hoodi-chaindata.tar.zst

# unzip snapshot to the ledger path
tar --use-compress-program=unzstd -xvf ${HOODI_CURRENT_TARBALL_DATE}-hoodi-chaindata.tar.zst -C  ./data/hoodi-geth
```

## 3 Start the service

If you use da-indexer

```
docker-compose -f docker-compose-hoodi-upgrade-da-indexer.yml up -d 
```

Otherwise

```
docker-compose -f docker-compose-hoodi-upgrade-beacon.yml up -d 
```
