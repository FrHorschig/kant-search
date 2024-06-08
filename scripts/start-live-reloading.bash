#!/bin/bash

function prefix() {
    local tag=$1
    local color=$2
    while IFS= read -r line; do
        echo -e "\e[${color}m${tag}: $line\e[0m"
    done
}
function stop() {
    pkill -f "kant-search-go-backend"
    kill %2 %3
}
trap stop SIGINT

export KSDB_USER=kantsearch
export KSDB_PASSWORD=kantsearch
export KSDB_NAME=kantsearch
export KSDB_PORT=5432

# database
cd kant-search-database
make
cd ..
docker run --rm \
    -v "$(pwd)"/volumes:/var/lib/postgresql/data \
    -e POSTGRES_USER=$KSDB_USER \
    -e POSTGRES_PASSWORD=$KSDB_PASSWORD \
    -e POSTGRES_DB=$KSDB_NAME \
    -p $KSDB_PORT:$KSDB_PORT \
    ghcr.io/frhorschig/kant-search-database:latest | prefix "DB" "34" &

# backend
export KSGO_DB_HOST=localhost
export KSGO_DB_SSLMODE=disable
export KSGO_ALLOW_ORIGINS=http://localhost:4200
export KSGO_DISABLE_SSL=true
export KSGO_PYTHON_BIN_PATH="src_py/.venv/bin/python3"
export KSGO_PYTHON_SCRIPT_PATH="src_py/split_text.py"
cd kant-search-backend && ~/go/bin/modd | prefix "Go" "32" &

# frontend
cd kant-search-frontend && ng serve | prefix "Ng" "31" &

wait
