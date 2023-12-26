# Simple Mantle Node

## Required Software

- [docker](https://docs.docker.com/engine/install/)
- [node](https://nodejs.org/en/download/)
- [foundry](https://github.com/foundry-rs/foundry/releases)

## Recommended Hardware

- 16GB+ RAM
- 8C+ CPU
- 500GB+ disk (HDD works for now, SSD is better)
- 10mb/s+ download

## Approximate Disk Usage

Usage as of 2023-12-20:

- Archive node: ~20gb

## Installation and Setup Instructions


### Configure Docker as a Non-Root User (Optional)

If you're planning to run Docker as a root user, you can safely skip this step.
However, if you're using Docker as a non-root user, you'll need to add yourself to the `docker` user group:

```sh
sudo usermod -a -G docker `whoami`
```

You'll need to log out and log in again for this change to take effect.



### Generate the 'jwt_secret_txt' file and the 'p2p_node_key_txt'

```sh
sudo node -e "console.log(require('crypto').randomBytes(32).toString('hex'))" > sepolia/secret/jwt_secret_txt

sudo cast w n |grep "Private Key" |awk -F ": " '{print $2}' |sed 's/0x//' > sepolia/secret/p2p_node_key_txt
```

### Operating the Node

#### Download latest snapshot from mantle 

We recommend that you start the node with latest shapshot, so that you don't need to wait a long time to sync data.

example: 

```sh 
mkdir -p ./data/sepolia-geth

# latest snapshot tarball
tarball="20231220-sepolia-chaindata.tar"

wget https://s3.ap-southeast-1.amazonaws.com/snapshot.sepolia.mantle.xyz/${tarball}

tar xf ${tarball} -C ./data/sepolia-geth

```

Check the data was unarchived successfully: 
```sh 
$ ls ./data/sepolia-geth
chaindata 
```

#### Start

```sh
docker-compose -f docker-compose-seoplia.yml up -d 
```

Will start the node in a detatched shell (`-d`), meaning the node will continue to run in the background.
You will need to run this again if you ever turn your machine off.

The first time you start the node it synchronizes from regenesis (December 1th, 2022) to the present.
This process takes hours.

#### Stop

```sh
docker-compose -f docker-compose-seoplia.yml down
```

Will shut down the node without wiping any volumes.
You can safely run this command and then restart the node again.

#### Wipe

```sh
docker-compose -f docker-compose-seoplia.yml down -v
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

## How To Check If The Deployment Is Successful

### Check Service

If the service status is 'up,' it means that the service has started without any issues.

```sh
docker-compose -f docker-compose-sepolia.yaml ps
```

### Check Data

Use the command 'cast bn' to execute multiple times and check if the height increases.
Use 'cast bl block' command to check whether stateroot and blockhash are consistent.

example: 

```sh
cast bl 971982 |egrep "state|hash"
cast bl 971982  --rpc-url https://rpc0-op-geth.sepolia.mantle.xyz |egrep "state|hash"
```
