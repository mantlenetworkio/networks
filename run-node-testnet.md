# Simple Mantle Node

## Required Software

- [docker](https://docs.docker.com/engine/install/)
- [node](https://nodejs.org/en/download/)
- [foundry](https://github.com/foundry-rs/foundry/releases)

## Recommended Hardware

- 16GB+ RAM
- 8C+ CPU
- 1000GB+ disk (HDD works for now, SSD is better)
- 10mb/s+ download

## Installation and Setup Instructions


### Init to generate the 'jwt_secret_txt' file and the 'p2p_node_key_txt'

```sh
cd networks/


mkdir goerli/secret

node -e "console.log(require('crypto').randomBytes(32).toString('hex'))" > goerli/secret/jwt_secret_txt

cast w n |grep -i "Private Key" |awk -F ": " '{print $2}' |sed 's/0x//' > goerli/secret/p2p_node_key_txt
```

### Operating the Node

#### Download latest snapshot from mantle 

We recommend that you start the node with latest shapshot, so that you don't need to wait a long time to sync data.

example: 

```sh 
mkdir -p ./data/testnet-geth

# latest snapshot tarball
linux:
date=$(date -d "2 days ago" +%Y%m%d)
mac:
date=$(date -v-2d +%Y%m%d)

tarball="$date-testnet1-chaindata.tar"

wget https://s3.ap-southeast-1.amazonaws.com/snapshot.sepolia.mantle.xyz/20240228-testnet1-chaindata.tar


tar xf ${tarball} -C ./data/testnet-geth

```

Check the data was unarchived successfully: 
```sh 
$ ls ./data/testnet-geth
chaindata 
```

#### Start

```sh
docker-compose -f docker-compose-testnet.yml up -d 
```

Will start the node in a detatched shell (`-d`), meaning the node will continue to run in the background.
You will need to run this again if you ever turn your machine off.

The first time you start the node it synchronizes from regenesis (December 1th, 2022) to the present.
This process takes hours.

#### Stop

```sh
docker-compose -f docker-compose-testnet.yml down
```

Will shut down the node without wiping any volumes.
You can safely run this command and then restart the node again.

#### Wipe

```sh
docker-compose -f docker-compose-testnet.yml down -v
```

Will completely wipe the node by removing the volumes that were created for each container.
Note that this is a destructive action, be very careful!

#### Logs

```sh
docker-compose logs <service name>
```

Will display the logs for a given service.
You can also follow along with the logs for a service in real time by adding the flag `-f`.

The available services are:
- [`op-geth`](#mantle-node)
- [`op-node`](#mantle-node)


#### Update

```sh
docker-compose pull
```

Will download the latest images for any services where you haven't hard-coded a service version.
Updates are regularly pushed to improve the stability of Mantle nodes or to introduce new quality-of-life features like better logging and better metrics.
I recommend that you run this command every once in a while (once a week should be more than enough).

## How To Check If The Deployment Is Successful

### Check Service

If the service status is 'up,' it means that the service has started without any issues.

```sh
docker-compose -f docker-compose-testnet.yml ps
```

### Check Data

Use the command 'cast bn' to execute multiple times and check if the height increases.

example: 

```sh
cast bn
cast bn --rpc-url  https://rpc.testnet.mantle.xyz 
```

Use the command 'cast rpc optimism_syncStatus' to execute multiple times and check if the safe_l2 and inalized_l2 increases.
It may need to be increased after thirty minutes

example: 

```sh
cast rpc optimism_syncStatus --rpc-url localhost:9545 |jq .finalized_l2.number

cast rpc optimism_syncStatus --rpc-url localhost:9545 |jq .safe_l2.number
```