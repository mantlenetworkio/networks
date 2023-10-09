# Simple Mantle Node

## Required Software

- [docker](https://docs.docker.com/engine/install/)

## Recommended Hardware

- 16GB+ RAM
- 1000GB+ disk (HDD works for now, SSD is better)
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
mkdir -p ./data/geth

# latest snapshot tarball
tarball="20231007-mainnet-chaindata.tar"

wget https://s3.ap-southeast-1.amazonaws.com/snapshot.mantle.xyz/${tarball}

tar vxf ${tarball} -C ./data/geth

```

Check the data was unarchived successfully: 
```sh 
$ ls ./data/geth
chaindata 
```

> note: **please change the ETH1_HTTP accordingly in docker-compose-mainnet.yml **:  this might cause sync failed

#### Start

```sh
docker-compose -f docker-compose-mainnet.yml up -d
```

Will start the node in a detatched shell (`-d`), meaning the node will continue to run in the background.
You will need to run this again if you ever turn your machine off.

The first time you start the node it synchronizes from regenesis (December 1th, 2022) to the present.
This process takes hours.

> note: if sync speed is slow , You could try to use https://dtl-us.mantle.xyz for US , https://dtl-eu.mantle.xyz/ for EU, https://dtl-ap.mantle.xyz/ for APAC . You could find this config in ./mainnet/envs/geth.env, the default value is : https://dtl.mantle.xyz .

#### Stop

```sh
docker-compose -f docker-compose-mainnet.yml down
```

Will shut down the node without wiping any volumes.
You can safely run this command and then restart the node again.

#### Wipe

```sh
docker-compose -f docker-compose-mainnet.yml down -v
```

Will completely wipe the node by removing the volumes that were created for each container.
Note that this is a destructive action, be very careful!

#### Logs

```sh
docker-compose logs <service name>
```

Will display the logs for a given service.
You can also follow along with the logs for a service in real time by adding the flag `-f`.




