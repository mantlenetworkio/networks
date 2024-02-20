# Simple Mantle Node

## Required Software

- [docker](https://docs.docker.com/engine/install/)

## Recommended Hardware

- 16GB+ RAM
- 500GB+ disk (HDD works for now, SSD is better)
- 10mb/s+ download

## Approximate Disk Usage

Usage as of 2024-01-17:

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
tarball="20240117-testnet-chaindata.tar"


wget https://s3.ap-southeast-1.amazonaws.com/static.testnet.mantle.xyz/${tarball}

tar xf ${tarball} -C ./data/geth

```

Check the data was unarchived successfully: 
```sh 
$ ls ./data/geth
chaindata 
```

#### Start

```sh
docker-compose -f docker-compose.yml up -d 
```

Will start the node in a detatched shell (`-d`), meaning the node will continue to run in the background.
You will need to run this again if you ever turn your machine off.

The first time you start the node it synchronizes from regenesis (December 1th, 2022) to the present.
This process takes hours.

#### Stop

```sh
docker-compose -f docker-compose.yml down
```

Will shut down the node without wiping any volumes.
You can safely run this command and then restart the node again.

#### Wipe

```sh
docker-compose -f docker-compose.yml down -v
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
Updates are regularly pushed to improve the stability of Mantle nodes or to introduce new quality-of-life features like better logging and better metrics.
I recommend that you run this command every once in a while (once a week should be more than enough).


