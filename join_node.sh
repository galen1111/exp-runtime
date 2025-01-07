#!/usr/bin/env bash

#################################################
#### Ensure we are in the right path. ###########
#################################################
if [[ 0 -eq $(echo $0 | grep -c '^/') ]]; then
    # relative path
    EXEC_PATH=$(dirname "`pwd`/$0")
else
    # absolute path
    EXEC_PATH=$(dirname "$0")
fi

EXEC_PATH=$(echo ${EXEC_PATH} | sed 's@/\./@/@g' | sed 's@/\.*$@@')
cd $EXEC_PATH || exit 1
#################################################

# EXP_NODE_DATA_DIR=
# EXP_NODE_FEE_RECIPIENT=
# EXP_NODE_BIN_E_CLIENT=
# EXP_NODE_BIN_C_CLIENT=
# EXP_NODE_BIN_SCD=
# EXP_NODE_BIN_EXPANDER=
# EXP_NODE_EXT_IP=

# Example:
#
# git clone https://github.com/galen1111/exp-runtime.git
# cp -rp exp-runtime/genesis_testnet /tmp/genesis
#
# EXP_NODE_GENESIS=/tmp/genesis

# Example:
#
# EXP_NODE_PEER="34.171.4.135"

if [[ "" == $EXP_NODE_DATA_DIR ]]; then
    EXP_NODE_DATA_DIR="/tmp/__EXP_NODE_DATA_DIR__"
    echo "No \$EXP_NODE_DATA_DIR set, fallback to the default value: $EXP_NODE_DATA_DIR"
fi

if [[ "" == $EXP_NODE_FEE_RECIPIENT ]]; then
    EXP_NODE_FEE_RECIPIENT="0x8943545177806ED17B9F23F0a21ee5948eCaa776"
    echo "No \$EXP_NODE_FEE_RECIPIENT set, fallback to the default value: $EXP_NODE_FEE_RECIPIENT"
fi

if [[ "" == $EXP_NODE_BIN_E_CLIENT ]]; then
    EXP_NODE_BIN_E_CLIENT="exp-e-client"
    echo "No \$EXP_NODE_BIN_E_CLIENT set, fallback to the default value: $EXP_NODE_BIN_E_CLIENT(\$PATH)"
fi

if [[ "" == $EXP_NODE_BIN_C_CLIENT ]]; then
    EXP_NODE_BIN_C_CLIENT="exp-c-client"
    echo "No \$EXP_NODE_BIN_C_CLIENT set, fallback to the default value: $EXP_NODE_BIN_C_CLIENT(\$PATH)"
fi

if [[ "" == $EXP_NODE_BIN_SCD ]]; then
    EXP_NODE_BIN_SCD="scd"
    echo "No \$EXP_NODE_BIN_SCD set, fallback to the default value: $EXP_NODE_BIN_SCD(\$PATH)"
fi

if [[ "" == $EXP_NODE_BIN_EXPANDER ]]; then
    EXP_NODE_BIN_EXPANDER="expander-exec"
    echo "No \$EXP_NODE_BIN_EXPANDER set, fallback to the default value: $EXP_NODE_BIN_EXPANDER(\$PATH)"
fi

if [[ "" == $EXP_NODE_GENESIS ]]; then
    echo -e "\x1b[31;1m\$EXP_NODE_GENESIS not set !!\x1b[0m"
    exit 1
fi

if [[ "" == $EXP_NODE_PEER ]]; then
    echo -e "\x1b[31;1m\$EXP_NODE_PEER not set !!\x1b[0m"
    exit 1
fi

for bin in "openssl" "curl" "jq"; do
    which $bin 2>/dev/null
    if [[ 0 -ne $? ]]; then
        echo "`$bin` not found in your \$PATH"
        exit 1
    fi
done

mkdir -p ${EXP_NODE_DATA_DIR}/{el,cl/{bn,vc}} || exit 1

openssl rand -hex 32 | tr -d "\n" > ${EXP_NODE_DATA_DIR}/auth.jwt || exit 1

if [ ! -d ${EXP_NODE_DATA_DIR}/genesis ]; then
    cp -rp $EXP_NODE_GENESIS ${EXP_NODE_DATA_DIR}/genesis || exit 1
fi

pkill scd
pkill exp-e-client
pkill exp-c-client

############################################
############################################
sleep 1
############################################
############################################

${EXP_NODE_BIN_SCD} -d >/tmp/scd.log 2>&1

############################################
############################################
echo "scd sync, wait 60 seconds.."; sleep 60
############################################
############################################

if [ ! -d ${EXP_NODE_DATA_DIR}/el/logs ] || [ "$1" == 'reinit' ]; then
    mkdir -p ${EXP_NODE_DATA_DIR}/el/logs || exit 1
    $EXP_NODE_BIN_E_CLIENT init --datadir=${EXP_NODE_DATA_DIR}/el --state.scheme=hash \
        ${EXP_NODE_DATA_DIR}/genesis/genesis.json >${EXP_NODE_DATA_DIR}/el/logs/el.log 2>&1 || exit 1
fi

boot_nodes=$(curl -X POST -H "Content-Type: application/json" -d '{"jsonrpc":"2.0","method":"admin_nodeInfo","params":[],"id":1}' "${EXP_NODE_PEER}:8545" | jq '.result.enode' | sed 's/"//g')
EL_EXTRA_OPTS=" --bootnodes=${boot_nodes}"

if [[ "" != $EXP_NODE_EXT_IP ]]; then
    EL_EXTRA_OPTS="${EL_EXTRA_OPTS} --nat=extip:${EXP_NODE_EXT_IP}"
fi

cmd="nohup ${EXP_NODE_BIN_E_CLIENT} \
    --syncmode=full \
    --gcmode=archive \
    --networkid=$(grep -Po '(?<="chainId":)\s*\d+' ${EXP_NODE_DATA_DIR}/genesis/genesis.json | tr -d ' ') \
    --datadir=${EXP_NODE_DATA_DIR}/el \
    --log.file=${EXP_NODE_DATA_DIR}/el/logs/el.log \
    --log.compress \
    --log.rotate \
    --log.maxsize=12 \
    --log.maxbackups=20 \
    --state.scheme=hash \
    --port=30303 \
    --discovery.port=30303 \
    --discovery.v5 \
    --http --http.addr=0.0.0.0 --http.port=8545 --http.vhosts='*' --http.corsdomain='*' \
    --http.api='eth,net,txpool,web3' \
    --ws --ws.addr=0.0.0.0 --ws.port=8546 --ws.origins='*' \
    --ws.api='eth,net,txpool,web3' \
    --authrpc.addr=127.0.0.1 --authrpc.port=8551 \
    --authrpc.jwtsecret=${EXP_NODE_DATA_DIR}/auth.jwt \
    --metrics \
    --metrics.addr 0.0.0.0 \
    --metrics.port=6060 \
    ${EL_EXTRA_OPTS} >/dev/null 2>&1 &"

echo -e "\n== $(date) ==\n\n$cmd\n" >>${EXP_NODE_DATA_DIR}/mgmt.log
eval $cmd

############################################
############################################
sleep 1
############################################
############################################

cl_enr=$(curl "http://${EXP_NODE_PEER}:5052/eth/v1/node/identity" | jq '.data.enr' | sed 's/"//g')
cl_peer_id=$(curl "http://${EXP_NODE_PEER}:5052/eth/v1/node/identity" | jq '.data.peer_id' | sed 's/"//g')

CL_EXTRA_OPTS=" --boot-nodes=${cl_enr} --trusted-peers=${cl_peer_id}"

if [[ "" != $EXP_NODE_EXT_IP ]]; then
    CL_EXTRA_OPTS="${CL_EXTRA_OPTS} --disable-enr-auto-update --enr-address=${EXP_NODE_EXT_IP}"
fi

cmd="nohup ${EXP_NODE_BIN_C_CLIENT} beacon_node \
    --testnet-dir=${EXP_NODE_DATA_DIR}/genesis \
    --datadir=${EXP_NODE_DATA_DIR}/cl/bn \
    --logfile=${EXP_NODE_DATA_DIR}/cl/bn/logs/cl.bn.log \
    --logfile-compress \
    --logfile-max-size=12 \
    --logfile-max-number=20 \
    --staking \
    --reconstruct-historic-states \
    --epochs-per-migration=18446744073709551615 \
    --slots-per-restore-point=32 \
    --disable-upnp \
    --disable-packet-filter \
    --subscribe-all-subnets \
    --listen-address=0.0.0.0 \
    --port=9000 \
    --discovery-port=9000 \
    --quic-port=9001 \
    --enable-private-discovery \
    --execution-endpoints='http://127.0.0.1:8551' \
    --jwt-secrets=${EXP_NODE_DATA_DIR}/auth.jwt \
    --suggested-fee-recipient=${EXP_NODE_FEE_RECIPIENT} \
    --http --http-address=0.0.0.0 \
    --http-port=5052 --http-allow-origin='*' \
    --metrics --metrics-address=0.0.0.0 \
    --metrics-port=5054 --metrics-allow-origin='*' \
    --checkpoint-sync-url=http://${EXP_NODE_PEER}:5052 \
    ${CL_EXTRA_OPTS} >/dev/null 2>&1 &"

echo -e "\n== $(date) ==\n\n$cmd\n" >>${EXP_NODE_DATA_DIR}/mgmt.log
eval $cmd

############################################
############################################
sleep 1
############################################
############################################

cmd="nohup ${EXP_NODE_BIN_C_CLIENT} validator_client \
    --testnet-dir=${EXP_NODE_DATA_DIR}/genesis \
    --datadir=${EXP_NODE_DATA_DIR}/cl/vc \
    --logfile=${EXP_NODE_DATA_DIR}/cl/vc/logs/cl.vc.log \
    --logfile-compress \
    --logfile-max-size=12 \
    --logfile-max-number=20 \
    --beacon-nodes='http://127.0.0.1:5052' \
    --init-slashing-protection \
    --suggested-fee-recipient=${EXP_NODE_FEE_RECIPIENT} \
    --unencrypted-http-transport \
    --enable-doppelganger-protection \
    --http --http-address="127.0.0.1" \
    --http-port=5062 --http-allow-origin='*' \
    --metrics --metrics-address=0.0.0.0 \
    --metrics-port=5064 --metrics-allow-origin='*' \
    >/dev/null 2>&1 &"

echo -e "\n== $(date) ==\n\n$cmd\n" >>${EXP_NODE_DATA_DIR}/mgmt.log
eval $cmd
