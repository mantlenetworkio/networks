# mantle-node Helm chart

A generic Helm chart for deploying a Mantle RPC node (execution layer +
`op-node` rollup verifier) on Kubernetes. One chart, three networks: Mantle
**Hoodi testnet**, **Sepolia testnet**, and **Mainnet**.

The chart mirrors the `docker-compose-*-upgrade-beacon.yml` files in this
repository:

| Network | EL client | docker-compose source |
|---------|-----------|------------------------|
| hoodi   | `op-reth` | `docker-compose-hoodi-upgrade-beacon.yml` |
| sepolia | `op-geth` | `docker-compose-sepolia-upgrade-beacon.yml` |
| mainnet | `op-geth` | `docker-compose-mainnetv2-upgrade-beacon.yml` |

---

## What gets deployed

- A `StatefulSet` for the execution layer (`op-reth` on hoodi, `op-geth` on
  sepolia / mainnet) with a PVC for chain data. An `initContainer` always
  downloads + extracts the latest official Mantle snapshot from S3 on first
  boot (and is a no-op afterwards).
- A `StatefulSet` for `op-node` with a small PVC for peerstore / discovery
  DB. The `rollup.json` config is mounted from a `ConfigMap` that the chart
  builds from `<network>/rollup.json` in this repo via a symlink under
  `chart/mantle-node/networks/<network>/rollup.json`.
- A `Secret` holding the engine-API JWT and the op-node libp2p key (auto-
  generated on first install if not supplied, preserved across upgrades).
- `ClusterIP` services exposing the EL HTTP / WS / authrpc / metrics ports
  and the op-node RPC / metrics ports.

`genesis.json` is **not** shipped by the chart:
- For `op-reth` (hoodi) the snapshot tarball already contains
  `/db/genesis.json`, which `--chain=/db/genesis.json` consumes directly.
- For `op-geth` (sepolia / mainnet) genesis is baked into the image and
  selected via `--networkid`, so no file is needed at runtime.

---

## Prerequisites

- Kubernetes 1.23+
- Helm 3.8+
- A default `StorageClass`, or one you can pass via
  `--set el.persistence.storageClass=...`
- An L1 RPC endpoint and an L1 beacon endpoint (or the
  [Mantle DA indexer](https://da-indexer-api.hoodi.mantle.xyz) for hoodi)

---

## Quick start

```bash
git clone https://github.com/mantle-xyz/networks.git
cd networks
```

Edit the L1 endpoints in the per-network values file you plan to use:

```yaml
# chart/mantle-node/hoodi.values.yaml (also: sepolia.values.yaml, mainnet.values.yaml)
l1:
  rpc:    "https://your-l1-rpc"
  beacon: "https://your-l1-beacon"   # or https://da-indexer-api.hoodi.mantle.xyz for hoodi
```

Then install:

```bash
# Hoodi testnet
helm install hoodi ./chart/mantle-node \
  -f ./chart/mantle-node/hoodi.values.yaml \
  --namespace mantle-hoodi --create-namespace

# Sepolia testnet
helm install sepolia ./chart/mantle-node \
  -f ./chart/mantle-node/sepolia.values.yaml \
  --namespace mantle-sepolia --create-namespace

# Mainnet
helm install mainnet ./chart/mantle-node \
  -f ./chart/mantle-node/mainnet.values.yaml \
  --namespace mantle-mainnet --create-namespace
```

---

## Verifying

```bash
# Watch pods come up
kubectl -n mantle-hoodi get pods -w

# Tail logs (snapshot download progress shows in the EL pod's initContainer)
kubectl -n mantle-hoodi logs -f sts/hoodi-mantle-node-el -c fetch-snapshot
kubectl -n mantle-hoodi logs -f sts/hoodi-mantle-node-el
kubectl -n mantle-hoodi logs -f sts/hoodi-mantle-node-op-node

# Query block height (port-forward, then run in another shell)
kubectl -n mantle-hoodi port-forward svc/hoodi-mantle-node-el 8545:8545 &
cast bn

# Sync status from op-node
kubectl -n mantle-hoodi port-forward svc/hoodi-mantle-node-op-node 9545:8545 &
cast rpc optimism_syncStatus --rpc-url localhost:9545 | jq .safe_l2.number
cast rpc optimism_syncStatus --rpc-url localhost:9545 | jq .finalized_l2.number
```

---

## Snapshot bootstrap

The chart **always** bootstraps the EL data PVC from the latest official
Mantle snapshot on S3, via an `initContainer` on the EL `StatefulSet`. It
reads `<baseUrl>/current.info` to find the current snapshot tag, then
downloads and `zstd`-extracts `<baseUrl>/<tag>-<tarballSuffix>` into the
PVC.

The init container is a no-op when the data directory already contains
chain data (`/db/db` for op-reth, `/db/geth/chaindata` for op-geth), so it
is safe across pod restarts and `helm upgrade`.

Snapshot URLs are pre-configured per network:

| Network | `snapshot.baseUrl`                  | `tarballSuffix`              | `extractSubpath` |
|---------|-------------------------------------|------------------------------|------------------|
| hoodi   | `s3.../snapshot.hoodi.mantle.xyz`   | `hoodi.tar.zst`              | `""`             |
| sepolia | `s3.../snapshot.sepolia.mantle.xyz` | `sepolia-chaindata.tar.zst`  | `geth`           |
| mainnet | `s3.../snapshot.mantle.xyz`         | `mainnet-chaindata.tar.zst`  | `geth`           |

---

## Common overrides

| Setting | Default | Notes |
|---------|---------|-------|
| `l1.rpc` | _required, edit values file_ | L1 execution RPC |
| `l1.beacon` | _required, edit values file_ | L1 beacon / blob endpoint, or Mantle DA indexer |
| `secrets.jwtSecret` | auto-generated | 32-byte hex; set for stable identity |
| `secrets.p2pNodeKey` | auto-generated | 32-byte hex; set for stable identity |
| `el.persistence.size` | 200Gi (hoodi) / 500Gi (sepolia) / 2000Gi (mainnet) | Adjust per network growth |
| `el.persistence.storageClass` | cluster default | e.g. `gp3`, `ssd` |
| `el.service.type` | ClusterIP | Switch to `NodePort` or `LoadBalancer` for external RPC |
| `el.snapshot.baseUrl` | per-network | S3 base URL with `current.info` + tarballs |
| `el.snapshot.tarballSuffix` | per-network | Filename suffix after `<date>-` |
| `el.snapshot.extractSubpath` | per-network | Subdir under `/db` to extract into (`""` for op-reth, `geth` for op-geth) |
| `opNode.persistence.size` | 10Gi | peerstore + discovery DB |

See `values.yaml` for the full schema.

---

## Upgrading

```bash
git pull
helm upgrade hoodi ./chart/mantle-node \
  -f ./chart/mantle-node/hoodi.values.yaml \
  --namespace mantle-hoodi
```

The chart annotates pods with checksums of the snapshot script and rollup
ConfigMaps, so changes to either trigger a pod rollout.

---

## Uninstalling

```bash
helm uninstall hoodi -n mantle-hoodi
# PVCs are NOT deleted by helm uninstall. Remove them manually if desired:
kubectl -n mantle-hoodi delete pvc -l app.kubernetes.io/instance=hoodi
```
