# Simple Mantle Node

## Required Software

* [docker](https://docs.docker.com/engine/install/)
* [node](https://nodejs.org/en/download/)
* [foundry](https://github.com/foundry-rs/foundry/releases)
* [zstd](https://github.com/facebook/zstd)
* [aira2](https://aria2.github.io/)

## Recommended Hardware

* 16GB+ RAM

* 8C+ CPU

* 500GB+ disk (HDD works for now, SSD is better)

* 10mb/s+ download

# Installation and Setup Instructions For New User

## Installation

### 1 Download repo

```
git clone https://github.com/mantlenetworkio/networks.git
```

### 2 Generate init file

generat the 'jwt\_secret\_txt' file and the 'p2p\_node\_key\_txt'

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

#### 4.1 Start with mantle da-indexer（recommend）

use mantle da-indexer to pull the data for rollup node, and you need to set up L1_RPC_SEPOLIA


```
export L1_RPC_SEPOLIA='https://rpc.ankr.com/eth_sepolia'  #please replace
docker-compose -f docker-compose-sepolia-upgrade-da-indexer.yml up -d 
```

Will start the node in a detached shell (`-d`), meaning the node will continue to run in the background. You will need to run this again if you ever turn your machine off.

Congratulations, the node has been deployed！

#### 4.2 Start with EigenDA and L1 beacon chain

use EigenDA and L1 beacon chain to pull the data for rollup node, 
you need set up L1_BEACON_SEPOLIA and L1_RPC_SEPOLIA ,L1_RPC_HOLESKY

L1_BEACON_SEPOLIA is for querying data from eth blob if eigenda failed 

L1_RPC_HOLESKY is for eigenda (eigenda only support holesky test network)
```
export L1_RPC_SEPOLIA='https://rpc.ankr.com/eth_sepolia'  #please replace
export L1_RPC_HOLESKY='https://rpc.ankr.com/eth_holesky'   #please replace
export L1_BEACON_SEPOLIA='https://eth-beacon-chain-sepolia.drpc.org/rest/'  #please replace

docker-compose -f docker-compose-sepolia-upgrade-beacon.yml up -d 
```

## Check Installation Result

Follow these steps to check if the installation is successful

### 1 Check Service

If the service status is 'up,' it means that the service has started without any issues.

```
docker-compose -f docker-compose-sepolia-upgrade-da-indexer.yml ps
```

### 2 Check Data

Use the command 'cast bn' to execute multiple times and check if the height increases.

example:

```
# query local op-geth latest block height
cast bn

# query latest block height from mantle rpc
cast bn --rpc-url  https://rpc.sepolia.mantle.xyz 
```

Use the command 'cast rpc optimism\_syncStatus' to execute multiple times and check if the safe\_l2 and inalized\_l2 increases. It may need to be increased after thirty minutes

example:

```
cast rpc optimism_syncStatus --rpc-url localhost:9545 |jq .finalized_l2.number

cast rpc optimism_syncStatus --rpc-url localhost:9545 |jq .safe_l2.number
```


query data from eigenproxy to confirm eigenproxy working (eigenda)

```
curl  -v http://127.0.0.1:3100/get/010000f901d5f850f842a0004b89b64c9068bcc5ee718469089461cc9d15176ec1774ded8deeb760f5d637a006a489746934a07df74d7089f141b41a3a9ad03338d729f9fb7380cb536252ad02cac480213701c401213701f901808301cf9872f873eba0b3442b9d2aebd5915bf535d3b43ac8888f2c9b0e54b9794f7c7c14b76926d56e820001826464832f5559a01520df76db0371961b3013d95a7a086e56643b6cc89b5afbf81a1d5c01868cc900832f55b0a090fbee953715da92a591f532409802012bc699d48ca72408a23b3884608e0b01b9010088b880e114817d065490b3945c80b827b710325dc50a768010f83855be9018070c249a7a314aed552c6beb02a5246d6598dca0b07f0cff206cbc881e36972b849339086457ff43cc0931213139c0703c16bb0de8ae6312d2cf440021aef44302e66e3504e989765d23d9cd805ee0fcb8c29e622f6c26a7306759875a007cb5a9b8692a97e2b2cf450a64df1bb75d95cef816e3b768834c22dc7d682087d89e10aeee6e3989d50b6cbd8fef1f1df57478eb6a61b10204125a74561231452eeaf70bef1800f79eaa6db6eec2a51ace404c8636c1b1b207675a842efbc69b9fd1bec79b8087a3dca0c15e3f42209f610dc84f5a532dd0ebff43d12eb8a79899abc4820001
```

## Other useful commands for Operator

### 1 Stop

```
docker-compose -f docker-compose-sepolia-upgrade-da-indexer.yml down
```

Will shut down the node without wiping any volumes. You can safely run this command and then restart the node again.

### 2 Wipe

```
docker-compose -f docker-compose-sepolia-upgrade-da-indexer.yml down -v
```

Will completely wipe the node by removing the volumes that were created for each container. Note that this is a destructive action, be very careful!

### 3 Logs

```
docker-compose logs <service name>
```

Will display the logs for a given service. You can also follow along with the logs for a service in real time by adding the flag `-f`.

The available services are:

* [`op-geth`](https://github.com/mantlenetworkio/networks/blob/ba6e673b4164864cf40768c95382423d5756bb67/run-node-sepolia.md#mantle-node)

* [`op-node`](https://github.com/mantlenetworkio/networks/blob/ba6e673b4164864cf40768c95382423d5756bb67/run-node-sepolia.md#mantle-node)

### 4 Update

```
docker-compose pull
```

Will download the latest images for any services where you haven't hard-coded a service version. Updates are regularly pushed to improve the stability of Mantle nodes or to introduce new quality-of-life features like better logging and better metrics. I recommend that you run this command every once in a while (once a week should be more than enough).

# 2025-01-16 Upgrade for historical user

## 1 Stop historical node

```
docker-compose -f docker-compose-sepolia.yml down
docker-compose -f docker-compose-sepolia-upgrade-da-indexer.yml down
```

## 2 Pull the latest code of this repo

```
# If your local code have changes, please use 'git stash' to cache first

git pull 
```

**If you start the node using your own way, please refer to the three files from this upgrade. Otherwise, it may cause irreversible damage to the node.**

## 3 Operating the Node

### 3.1 start with mantle da-indexer（recommend）


```
export L1_RPC_SEPOLIA='https://rpc.ankr.com/eth_sepolia'  #please replace
docker-compose -f docker-compose-sepolia-upgrade-da-indexer.yml up -d 
```

### 3.2 start with EigenDA and L1 beacon chain

use EigenDA and L1 beacon chain to pull the data for rollup node, 

you need to edit L1_BEACON_SEPOLIA and L1_RPC_SEPOLIA ,L1_RPC_HOLESKY

L1_BEACON_SEPOLIA is for querying data from eth blob if eigenda failed 

L1_RPC_HOLESKY is for eigenda (eigenda only support holesky test network)

then start with

```
export L1_RPC_SEPOLIA='https://rpc.ankr.com/eth_sepolia'  #please replace
export L1_RPC_HOLESKY='https://rpc.ankr.com/eth_holesky'   #please replace
export L1_BEACON_SEPOLIA='https://eth-beacon-chain-sepolia.drpc.org/rest/'  #please replace
docker-compose -f docker-compose-sepolia-upgrade-beacon.yml up -d 
```

## 4 Check data

Use the command 'cast bn' to execute multiple times and check if the height increases.

example:

```
# query local op-geth latest block height
cast bn

# query latest block height from mantle rpc
cast bn --rpc-url  https://rpc.sepolia.mantle.xyz 
```

Use the command 'cast rpc optimism\_syncStatus' to execute multiple times and check if the safe\_l2 and inalized\_l2 increases. It may need to be increased after thirty minutes

example:

```
cast rpc optimism_syncStatus --rpc-url localhost:9545 |jq .finalized_l2.number

cast rpc optimism_syncStatus --rpc-url localhost:9545 |jq .safe_l2.number
```

# Restore from snapshot

If your node's data is corrupted due to abnormal operations, please refer to the following steps for recovery

## 1 Clean up historical data

```
rm -fr ./data/sepolia-geth 
```

## 2 Download the latest data

```
mkdir -p ./data/sepolia-geth

# download the latest official snapshot
SEPOLIA_CURRENT_TARBALL_DATE=`curl https://s3.ap-southeast-1.amazonaws.com/snapshot.sepolia.mantle.xyz/current.info`
wget -c https://s3.ap-southeast-1.amazonaws.com/snapshot.sepolia.mantle.xyz/${SEPOLIA_CURRENT_TARBALL_DATE}-sepolia-chaindata.tar.zst

# unzip snapshot to the ledger path
tar --use-compress-program=unzstd -xvf ${SEPOLIA_CURRENT_TARBALL_DATE}-sepolia-chaindata.tar.zst -C  ./data/sepolia-geth
```

## 3 Start the service

If you use da-indexer

```
docker-compose -f docker-compose-sepolia-upgrade-da-indexer.yml up -d 
```

Otherwise

```
docker-compose -f docker-compose-sepolia-upgrade-beacon.yml up -d 
```


# 2025-07-5 Upgrade for historical user

## 1 Stop historical node

```
docker-compose -f docker-compose-sepolia.yml down
docker-compose -f docker-compose-sepolia-upgrade-da-indexer.yml down
```

## 2 Pull the latest code of this repo

```
# If your local code have changes, please use 'git stash' to cache first

git pull 
```

**If you start the node using your own way, please refer to the three files from this upgrade. Otherwise, it may cause irreversible damage to the node.**

## 3 Operating the Node

### 3.1 start with mantle da-indexer（recommend）


```
export L1_RPC_SEPOLIA='https://rpc.ankr.com/eth_sepolia'  #please replace
docker-compose -f docker-compose-sepolia-upgrade-da-indexer.yml up -d 
```

### 3.2 start with EigenDA and L1 beacon chain

use EigenDA and L1 beacon chain to pull the data for rollup node, 

you need to edit L1_BEACON_SEPOLIA and L1_RPC_SEPOLIA 

L1_BEACON_SEPOLIA is for querying data from eth blob if eigenda failed 


then start with

```
export L1_RPC_SEPOLIA='https://rpc.ankr.com/eth_sepolia'  #please replace
export L1_BEACON_SEPOLIA='https://eth-beacon-chain-sepolia.drpc.org/rest/'  #please replace
docker-compose -f docker-compose-sepolia-upgrade-beacon.yml up -d 
```

## 4 Check data

Use the command 'cast bn' to execute multiple times and check if the height increases.

example:

```
# query local op-geth latest block height
cast bn

# query latest block height from mantle rpc
cast bn --rpc-url  https://rpc.sepolia.mantle.xyz 
```

Use the command 'cast rpc optimism\_syncStatus' to execute multiple times and check if the safe\_l2 and inalized\_l2 increases. It may need to be increased after thirty minutes

example:

```
cast rpc optimism_syncStatus --rpc-url localhost:9545 |jq .finalized_l2.number

cast rpc optimism_syncStatus --rpc-url localhost:9545 |jq .safe_l2.number
```

# Restore from snapshot

If your node's data is corrupted due to abnormal operations, please refer to the following steps for recovery

## 1 Clean up historical data

```
rm -fr ./data/sepolia-geth 
```

## 2 Download the latest data

```
mkdir -p ./data/sepolia-geth

# download the latest official snapshot
SEPOLIA_CURRENT_TARBALL_DATE=`curl https://s3.ap-southeast-1.amazonaws.com/snapshot.sepolia.mantle.xyz/current.info`
wget -c https://s3.ap-southeast-1.amazonaws.com/snapshot.sepolia.mantle.xyz/${SEPOLIA_CURRENT_TARBALL_DATE}-sepolia-chaindata.tar.zst

# unzip snapshot to the ledger path
tar --use-compress-program=unzstd -xvf ${SEPOLIA_CURRENT_TARBALL_DATE}-sepolia-chaindata.tar.zst -C  ./data/sepolia-geth
```

## 3 Start the service

If you use da-indexer

```
docker-compose -f docker-compose-sepolia-upgrade-da-indexer.yml up -d 
```

Otherwise

```
docker-compose -f docker-compose-sepolia-upgrade-beacon.yml up -d 
```
