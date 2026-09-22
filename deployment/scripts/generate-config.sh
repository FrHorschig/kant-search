#!/bin/bash

if [ "$#" -ne 4 ]; then
    echo "Usage: $0 <kant-search version number> <hostname> <base-path> <port>"
    exit 1
fi

# download config files
mkdir -p config/backend config/frontend
curl -L -o config/backend/volume-metadata.json https://github.com/FrHorschig/kant-search-backend/releases/download/$1/volume-metadata.json
curl -L -o config/ks-frontend-config.zip https://github.com/FrHorschig/kant-search-frontend/releases/download/$1/ks-frontend-config.zip
cd config/
unzip ks-frontend-config.zip
rm ks-frontend-config.zip
cd ..

# normalize base path
base_path=$3
while [[ $base_path == /* ]]; do
    base_path="${base_path#/}"
done
while [[ $base_path == */ ]]; do
    base_path="${base_path%/}"
done
base_path="/$base_path"
if [[ "$base_path" != "/" ]]; then
    base_path="${base_path}/"
fi

# replace placeholders
sed -i "s|<version>|$1|g" kant-search-stack.yml
sed -i "s|<hostname>|$2|g" kant-search-stack.yml
sed -i "s|<base-path>|${base_path}|" kant-search-stack.yml
sed -i "s|<port>|$4|g" kant-search-stack.yml

sed -i "s|http://localhost:5000/|https://$2${base_path}|" config/frontend/config.json
sed -i "s|<port>|$4|" config/reverse-proxy.conf
sed -i "s|<hostname>|$2|g" config/grafana/grafana.ini
sed -i "s|<base-path>|$base_path|g" config/grafana/grafana.ini

# create log directory
mkdir -p log/reverse-proxy
mkdir -p log/frontend
mkdir -p log/backend
