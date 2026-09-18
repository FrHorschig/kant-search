#!/bin/bash

if [ "$#" -ne 4 ]; then
    echo "Usage: $0 <kant-search version number> <hostname> <base-path> <port>"
    exit 1
fi

# Download config files for backend and frontend
mkdir -p config/backend config/frontend
curl -L -o config/backend/volume-metadata.json https://github.com/FrHorschig/kant-search-backend/releases/download/$1/volume-metadata.json
curl -L -o config/ks-frontend-config.zip https://github.com/FrHorschig/kant-search-frontend/releases/download/$1/ks-frontend-config.zip
cd config/
unzip ks-frontend-config.zip
rm ks-frontend-config.zip
cd ..

# Replace placeholders
sed -i "s|<version>|$1|g" kant-search-stack.yml
sed -i "s|<hostname>|$2|g" kant-search-stack.yml
sed -i "s|<base-path>|$3|" kant-search-stack.yml
sed -i "s|<port>|$4|g" kant-search-stack.yml

sed -i "s|<hostname>|$2|g" config/grafana/grafana.ini
sed -i "s|http://localhost:5000|https://$2${3:+$3/}|" config/frontend/config.json
sed -i "s|<port>|$4|" config/reverse-proxy.conf

# Create log directory
mkdir -p log/backend
