#!/bin/bash

USE_DEBUGGER=false
if [[ "$1" == "-d" ]]; then
    USE_DEBUGGER=true
fi

function prefix() {
    local tag=$1
    local color=$2
    while IFS= read -r line; do
        echo -e "\e[${color}m${tag}: $line\e[0m"
    done
}
function stop() {
    pkill -f "kant-search-backend"
    docker stop elasticsearch
}
trap stop SIGINT

export KSDB_URL="https://localhost"
export KSDB_PORT=9200
export KSDB_USER="elastic"
export KSDB_PWD="ES_PASSWORD"
export KSDB_CERT_HASH="ES_CERT_HASH"

# === database ===================================================
if ! docker network inspect elastic > /dev/null 2>&1; then
    docker network create elastic
fi
# pull in separate operation, so that w/o internet, the script can still start
ELASTIC_VERSION=8.18.1
docker pull docker.elastic.co/elasticsearch/elasticsearch:$ELASTIC_VERSION

KSDB_CONTAINER="elasticsearch"
docker run --rm --name $KSDB_CONTAINER \
    -e "discovery.type=single-node" \
    -e ELASTIC_PASSWORD=$KSDB_PWD \
    -p $KSDB_PORT:9200 \
    docker.elastic.co/elasticsearch/elasticsearch:$ELASTIC_VERSION | \
    grep -v '"log.level": "INFO"' | \
    prefix "ES" "34" &
sleep 45

cert_output=$(docker exec -i elasticsearch \
    openssl x509 -fingerprint -sha256 -in config/certs/http_ca.crt)
ES_CERT_HASH=$(echo "$cert_output" | \
    grep "SHA256 Fingerprint=" | \
    cut -d'=' -f2 | \
    tr -d ':')
export KSDB_CERT_HASH="$ES_CERT_HASH"

# === backend ====================================================
export KSGO_ALLOW_ORIGINS=*
export KSGO_DISABLE_SSL=true
start_live_reloading() {
    export KSGO_PYTHON_SCRIPT_PATH="src_py"
    export CONFIG_PATH="config"
    cd kant-search-backend && ~/go/bin/modd | prefix "Go" "32" &
}
start_debugging() {
    export KSGO_PYTHON_SCRIPT_PATH="../src_py"
    export CONFIG_PATH="../config"
    cd kant-search-backend/src && dlv debug --headless --listen=:2345 --api-version=2 --accept-multiclient --log 2>&1 | prefix "Go" "32" &
}
if $USE_DEBUGGER; then
    start_debugging
else
    start_live_reloading
fi

# === frontend ===================================================
cd kant-search-frontend && ng serve | prefix "Ng" "31" &

wait
