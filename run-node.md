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



### Configure the Node

Make a copy of `.env.example` named `.env`.

```sh
cp .env.example .env
```

Open `.env` with your editor of choice and fill out the environment variables listed inside that file.
Only the following variables are required:

| Variable Name                           | Description                                                               |
|-----------------------------------------|---------------------------------------------------------------------------|
| `NETWORK_NAME`                          | Network to run the node on ("mainnet" or "goerli")                            |
| `NODE_TYPE`                             | Type of node to run ("full" or "archive")                                      |
| `SYNC_SOURCE`                           | Where to sync data from ("l1" or "l2")                                        |
| `HEALTHCHECK__REFERENCE_RPC_PROVIDER`   | Another reference L2 node to check blocks against, just in case              |
| `FAULT_DETECTOR__L1_RPC_PROVIDER`       | L1 node RPC to check state roots against                                  |
| `DATA_TRANSPORT_LAYER__RPC_ENDPOINT`    | Node to get chain data from, must be an L1 node if `SYNC_SOURCE` is "l1" and vice versa for L2 |

You can get L1/L2 RPC endpoints from [these node providers](https://github.com/mantlenetworkio/networks/blob/main/goerli/testnet.md).

You can also modify any of the optional environment variables if you'd wish, but the defaults should work perfectly well for most people.
Just make sure not to change anything under the line marked "NO TOUCHING" or you might break something!

### Setting a Data Directory (Optional)

Please note that this is an *optional* step but might be useful for anyone who was confused as I was about how to make Docker point at disk other than your primary disk.
If you'd like your Docker data to live on a disk other than your primary disk, create a file `/etc/docker/daemon.json` with the following contents:

```json
{
    "data-root": "/mnt/<disk>/docker_data"
}
```

Make sure to restart docker after you do this or the changes won't apply:

```sh
sudo systemctl daemon-reload
sudo systemctl restart docker
```

Confirm that the changes were properly applied:

```sh
docker info | grep -i "Docker Root Dir"
```

### Operating the Node

#### Start

```sh
docker compose up -d
```

Will start the node in a detatched shell (`-d`), meaning the node will continue to run in the background.
You will need to run this again if you ever turn your machine off.

The first time you start the node it synchronizes from regenesis (December 1th, 2022) to the present.
This process takes hours.

#### Stop

```sh
docker compose down
```

Will shut down the node without wiping any volumes.
You can safely run this command and then restart the node again.

#### Wipe

```sh
docker compose down -v
```

Will completely wipe the node by removing the volumes that were created for each container.
Note that this is a destructive action, be very careful!

#### Logs

```sh
docker compose logs <service name>
```

Will display the logs for a given service.
You can also follow along with the logs for a service in real time by adding the flag `-f`.

The available services are:
- [`dtl` and `l2geth`](#mantle-node)
- [`healthcheck` and `fault-detector`](#healthcheck--fault-detector)
- [`prometheus`, `grafana`, and `influxdb`](#metrics-dashboard)


#### Update

```sh
docker compose pull
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

### Healthcheck

When you run your Optimism node using these instructions, you will also be running two services that monitor the health of your node and the health of the network.
The Healthcheck service will constantly compare the state computed by your node to the state of some other reference node.
This is a great way to confirm that your node is syncing correctly.

### Metrics Dashboard

Grafana is exposed at [http://localhost:3000](http://localhost:3000) and comes with one pre-loaded dashboard ("Simple Node Dashboard").
Simple Node Dashboard includes basic node information and will tell you if your node ever falls out of sync with the reference L2 node or if a state root fault is detected.

Use the following login details to access the dashboard:

* Username: `admin`
* Password: `mantle`

Navigate over to `Dashboards > Manage > Simple Node Dashboard` to see the dashboard, see the following gif if you need help:

