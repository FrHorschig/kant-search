#!/bin/bash

ES_CERT="scripts/elasticsearch.crt"
ES_CONTAINER="elasticsearch"
export KSDB_URL="https://localhost"
export KSDB_PORT=9200
export KSDB_USERNAME="elastic"
export KSDB_PASSWORD="es_password"
export KSGO_ALLOW_ORIGINS=*

export KSGO_DISABLE_SSL=true
export KSGO_DISABLE_LOGFILES=true

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
    docker stop $ES_CONTAINER
    rm $ES_CERT
    exit 130
}
trap stop SIGINT

# === database ===================================================
if ! docker network inspect elastic > /dev/null 2>&1; then
    docker network create elastic
fi
ES_VERSION=8.18.1
docker pull docker.elastic.co/elasticsearch/elasticsearch:$ES_VERSION

docker run --rm --name $ES_CONTAINER \
    -e "discovery.type=single-node" \
    -e ELASTIC_PASSWORD=$KSDB_PASSWORD \
    -p $KSDB_PORT:9200 \
    docker.elastic.co/elasticsearch/elasticsearch:$ES_VERSION | \
    prefix "ES" "34" &

until docker cp $ES_CONTAINER:/usr/share/elasticsearch/config/certs/http_ca.crt $ES_CERT 2>/dev/null; do
    echo "Waiting for ES container to start..."
    sleep 2
done
# until curl -s --cacert $ES_CERT -u "elastic:$KSDB_PASSWORD" "https://localhost:$KSDB_PORT/" >/dev/null 2>&1; do
#     echo "Waiting for ES container to start..."
#     sleep 2
# done

# === backend ====================================================
start_live_reloading() {
    export KSDB_CERT="../$ES_CERT"
    export KSGO_CONFIG_PATH="config"
    cd kant-search-backend && ~/go/bin/modd | prefix "Go" "32" &
}
start_debugging() {
    export KSDB_CERT="../../$ES_CERT"
    export KSGO_CONFIG_PATH="../config"
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
