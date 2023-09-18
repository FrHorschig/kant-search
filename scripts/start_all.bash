#!/bin/bash

project="kant-search"

function prefix() {
    local tag=$1
    local color=$2
    while IFS= read -r line; do
        echo -e "\e[${color}m${tag}: $line\e[0m"
    done
}
function stop() {
    pkill -f ""$project"-go-backend"
    kill %2 %3
}
trap stop SIGINT

# Build and run database container
cd "${project}-database"
make
cd ..
docker run --rm \
    -u "$USER" \
    -v "$(pwd)"/volumes:/var/lib/postgresql/data \
    -e POSTGRES_USER=kantsearch \
    -e POSTGRES_PASSWORD=kantsearch \
    -e POSTGRES_DB=kantsearch \
    -p 5432:5432 \
    "$project"-database | prefix "DB" "34" &

# Start backend and frontend with live reloading
cd "$project"-backend && source deployment/local_env.bash && ~/go/bin/modd | prefix "Go" "32" &
# cd "$project"-frontend && ng serve --ssl | prefix "Ng" "31" &

wait
