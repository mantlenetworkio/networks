#!/bin/bash

# 需要安装node命令,参考https://nodejs.org/en/download/
# 生成jwt secret
node -e "console.log(require('crypto').randomBytes(32).toString('hex'))" > secret/jwt_secret_txt

# 需要安装cast命令,参考https://github.com/foundry-rs/foundry/releases
# 生成op-node需要的EOA账号
cast w n |grep "Private Key" |awk -F ": " '{print $2}' |sed 's/0x//' > secret/p2p_node_key_txt