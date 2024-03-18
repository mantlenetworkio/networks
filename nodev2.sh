#!/bin/sh


#set up env
export OP_NODE_L1_ETH_RPC='wss://mainnet.gateway.tenderly.co' #change this
export OP_NODE_L2_ENGINE_RPC='http://localhost:8551'
export OP_NODE_L2_ENGINE_AUTH=./mainnet/secret/jwt_secret_txt
export OP_NODE_ROLLUP_CONFIG='./mainnet/rollup.json'
export OP_NODE_P2P_PRIV_PATH=./mainnet/secret/p2p_node_key_txt
export OP_NODE_VERIFIER_L1_CONFS='3'
export OP_NODE_RPC_ADDR='0.0.0.0'
export OP_NODE_RPC_PORT=8545
export OP_NODE_P2P_LISTEN_IP='0.0.0.0'
export OP_NODE_P2P_LISTEN_TCP_PORT=9003
export OP_NODE_P2P_LISTEN_UDP_PORT=9003
export OP_NODE_P2P_PEER_SCORING='light'
export OP_NODE_P2P_PEER_BANNING='true'
export OP_NODE_METRICS_ENABLED='true'
export OP_NODE_METRICS_ADDR='0.0.0.0'
export OP_NODE_METRICS_PORT=7300
export OP_NODE_PPROF_ENABLED='true'
export OP_NODE_PPROF_PORT=6060
export OP_NODE_PPROF_ADDR='0.0.0.0'
export OP_NODE_P2P_DISCOVERY_PATH='/op-node/opnode_discovery_db'
export OP_NODE_P2P_PEERSTORE_PATH='/op-node/opnode_peerstore_db'
export OP_NODE_INDEXER_SOCKET='da-indexer-api.mantle.xyz:443'
export OP_NODE_INDEXER_ENABLE='true'
export OP_NODE_L2_BACKUP_UNSAFE_SYNC_RPC=https://rpc.mantle.xyz
export OP_NODE_P2P_STATIC='/dns4/peer0.mantle.xyz/tcp/9003/p2p/16Uiu2HAmKVKzUAns2gLhZAz1PYcbnhY3WpxNxUZYeTN1x29tNBAW,/dns4/peer1.mantle.xyz/tcp/9003/p2p/16Uiu2HAm1AiZtVp8f5C8LvpSTAXC6GtwqAVKnB3VLawWYSEBmcFN,/dns4/peer2.mantle.xyz/tcp/9003/p2p/16Uiu2HAm2UHVKiPXpovs8VbbUQVPr7feBAqBJdFsH1z5XDiLEvHT'
export OP_NODE_SEQUENCER_ENABLED='false'
export OP_NODE_P2P_AGENT='mantle'
export OP_NODE_L2_ENGINE_SYNC_ENABLED='true'
export OP_NODE_L2_SKIP_SYNC_START_CHECK='true'
export OP_NODE_P2P_SYNC_REQ_RESP='true'


# start the geth node
echo "Starting Geth node"
exec op-node 
