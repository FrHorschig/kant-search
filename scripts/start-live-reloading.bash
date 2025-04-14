#!/bin/bash

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

KSDB_CONTAINER="elasticsearch"
docker run --rm --name $KSDB_CONTAINER \
    -e "discovery.type=single-node" \
    -p $KSDB_PORT:9200 \
    docker.elastic.co/elasticsearch/elasticsearch:8.17.4 | \
    grep -v '"log.level": "INFO"' | \
    prefix "ES" "34" &
sleep 20

pwd_output=$(yes y | docker exec -i "$KSDB_CONTAINER" \
    /usr/share/elasticsearch/bin/elasticsearch-reset-password -u elastic)
ES_PASSWORD=$(echo "$pwd_output" | \
    grep "New value:" | \
    awk '{print $3}')
export KSDB_PWD="$ES_PASSWORD"

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
export KSGO_PYTHON_BIN_PATH="src_py/.venv/bin/python3"
export KSGO_PYTHON_SCRIPT_PATH="src_py"
cd kant-search-backend && ~/go/bin/modd | prefix "Go" "32" &

# === frontend ===================================================
cd kant-search-frontend && ng serve | prefix "Ng" "31" &

wait
