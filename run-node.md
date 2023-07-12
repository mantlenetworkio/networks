# Simple Mantle Node

## Required Software

- [docker](https://docs.docker.com/engine/install/)

## Recommended Hardware

- 16GB+ RAM
- 500GB+ disk (HDD works for now, SSD is better)
- 10mb/s+ download

## Approximate Disk Usage

Usage as of 2022-09-21:

- Archive node: ~800gb
- Full node: ~60gb

## Installation and Setup Instructions

### Configure Docker as a Non-Root User (Optional)

If you're planning to run Docker as a root user, you can safely skip this step.
However, if you're using Docker as a non-root user, you'll need to add yourself to the `docker` user group:

```sh
sudo usermod -a -G docker `whoami`
```

You'll need to log out and log in again for this change to take effect.


### Operating the Node

#### Download latest snapshot from mantle 

We recommend that you start the node with latest shapshot, so that you don't need to wait a long time to sync data.

example: 

```sh 
mkdir data/geth

# yesterday's snapshot tarball
tarball=$(TZ=UTC date +"%Y%m%d" --date="yesterday")-testnet-chaindata.tar

wget https://s3.ap-southeast-1.amazonaws.com/static.testnet.mantle.xyz/${tarball}

tar xf ${tarball} -C data/geth

```

Check the data was unarchived successfully: 
```sh 
$ ls data/geth
LOCK  chaindata  nodekey  nodes  transactions.rlp
```

#### Start

```sh
docker-compose up -d
```

Will start the node in a detatched shell (`-d`), meaning the node will continue to run in the background.
You will need to run this again if you ever turn your machine off.

The first time you start the node it synchronizes from regenesis (December 1th, 2022) to the present.
This process takes hours.

#### Stop

```sh
docker-compose down
```

Will shut down the node without wiping any volumes.
You can safely run this command and then restart the node again.

#### Wipe

```sh
docker-compose down -v
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
- [`replica`](#mantle-node)


#### Update

```sh
docker-compose pull
```

Will download the latest images for any services where you haven't hard-coded a service version.
Updates are regularly pushed to improve the stability of Optimism nodes or to introduce new quality-of-life features like better logging and better metrics.
I recommend that you run this command every once in a while (once a week should be more than enough).

## What's Included

### Mantle Node

Currently, an mantle node can either sync from L1 or from other L2 nodes.
Syncing from L1 is generally the safest option but takes longer.
A node that syncs from L1 will also lag behind the tip of the chain depending on how long it takes for the Mantle Sequencer to publish transactions to Ethereum.
Syncing from L2 is faster but (currently) requires trusting the L2 node you're syncing from.

Many people are running nodes that sync from other L2 nodes, but I'd like to incentivize more people to run nodes that sync directly from L1.
As a result, I've set this repository up to sync from L1 by default.
I may later add the option to sync from L2 but I need to go do other things for a while.
