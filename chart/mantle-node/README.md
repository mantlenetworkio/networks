# mantle-node Helm chart

A generic Helm chart for deploying a Mantle RPC node (L2 execution client +
`op-node` rollup verifier) on Kubernetes. One chart, three networks: Mantle
**Hoodi testnet**, **Sepolia testnet**, and **Mainnet**.

The chart mirrors the `docker-compose-*-upgrade-beacon.yml` files in this
repository:

| Network | L2 client | docker-compose source |
|---------|-----------|------------------------|
| hoodi   | `op-reth` | `docker-compose-hoodi-upgrade-beacon.yml` |
| sepolia | `op-geth` | `docker-compose-sepolia-upgrade-beacon.yml` |
| mainnet | `op-geth` | `docker-compose-mainnetv2-upgrade-beacon.yml` |

---

## What gets deployed

- A `StatefulSet` for the L2 execution client (`op-reth` on hoodi, `op-geth`
  on sepolia / mainnet) with its own PVC for chain data.
- A `StatefulSet` for `op-node` with a small PVC for peerstore / discovery DB.
- A `Secret` holding the engine-API JWT and the op-node libp2p key (auto-
  generated on first install if not supplied, and preserved across upgrades).
- A `ConfigMap` of init scripts that fetch `genesis.json` and `rollup.json`
  from the `mantlenetworkio/networks` repo on each pod start (genesis.json is
  ~9 MB, which exceeds the 1 MB ConfigMap limit, so it cannot be embedded).
- `ClusterIP` services exposing the L2 HTTP / WS / authrpc / metrics ports
  and the op-node RPC / metrics ports.

---

## Prerequisites

- Kubernetes 1.23+
- Helm 3.8+
- A default `StorageClass`, or one you can pass via
  `--set l2.persistence.storageClass=...`
- An L1 RPC endpoint and an L1 beacon endpoint (or the
  [Mantle DA indexer](https://da-indexer-api.hoodi.mantle.xyz) for hoodi)

---

## Quick start

```bash
git clone https://github.com/mantlenetworkio/networks.git
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

# Tail logs
kubectl -n mantle-hoodi logs -f sts/hoodi-mantle-node-l2
kubectl -n mantle-hoodi logs -f sts/hoodi-mantle-node-op-node

# Query block height (port-forward, then run in another shell)
kubectl -n mantle-hoodi port-forward svc/hoodi-mantle-node-l2 8545:8545 &
cast bn

# Sync status from op-node
kubectl -n mantle-hoodi port-forward svc/hoodi-mantle-node-op-node 9545:8545 &
cast rpc optimism_syncStatus --rpc-url localhost:9545 | jq .safe_l2.number
cast rpc optimism_syncStatus --rpc-url localhost:9545 | jq .finalized_l2.number
```

---

## Snapshot bootstrap

The chart **always** bootstraps the L2 data PVC from the latest official
Mantle snapshot on S3, via an `initContainer` on the L2 `StatefulSet`. It
reads `<baseUrl>/current.info` to find the current snapshot tag, then
downloads and `zstd`-extracts `<baseUrl>/<tag>-<tarballSuffix>` into the
PVC.

The init container is a no-op when the data directory already contains
chain data (`/db/db` for op-reth, `/db/geth/chaindata` for op-geth), so it
is safe across pod restarts and `helm upgrade`.

Snapshot URLs are pre-configured per network:

| Network | `snapshot.baseUrl` | `tarballSuffix` |
|---------|--------------------|-----------------|
| hoodi   | `s3.../snapshot.hoodi.mantle.xyz`   | `hoodi.tar.zst` |
| sepolia | `s3.../snapshot.sepolia.mantle.xyz` | `sepolia-chaindata.tar.zst` |
| mainnet | `s3.../snapshot.mantle.xyz`         | `mainnet-chaindata.tar.zst` |

---

## Common overrides

| Setting | Default | Notes |
|---------|---------|-------|
| `l1.rpc` | _required, edit values file_ | L1 execution RPC |
| `l1.beacon` | _required, edit values file_ | L1 beacon / blob endpoint, or Mantle DA indexer |
| `secrets.jwtSecret` | auto-generated | 32-byte hex; set for stable identity |
| `secrets.p2pNodeKey` | auto-generated | 32-byte hex; set for stable identity |
| `l2.persistence.size` | 200Gi (hoodi) / 500Gi (sepolia) / 2000Gi (mainnet) | Adjust per network growth |
| `l2.persistence.storageClass` | cluster default | e.g. `gp3`, `ssd` |
| `l2.service.type` | ClusterIP | Switch to `NodePort` or `LoadBalancer` for external RPC |
| `l2.snapshot.baseUrl` | per-network | S3 base URL with `current.info` + tarballs |
| `l2.snapshot.tarballSuffix` | per-network | Filename suffix after `<date>-` |
| `l2.snapshot.extractSubpath` | per-network | Subdir under `/db` to extract into (`""` for op-reth, `geth` for op-geth) |
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

The chart annotates pods with a checksum of the init scripts ConfigMap, so
changes to `genesis.json`/`rollup.json` URLs trigger a pod rollout.

---

## Uninstalling

```bash
helm uninstall hoodi -n mantle-hoodi
# PVCs are NOT deleted by helm uninstall. Remove them manually if desired:
kubectl -n mantle-hoodi delete pvc -l app.kubernetes.io/instance=hoodi
```
