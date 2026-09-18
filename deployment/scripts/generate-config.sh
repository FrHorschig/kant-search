#!/bin/bash

if [ "$#" -ne 3 ]; then
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

# Replace `<hostname>` placeholder
sed -i -E "s|(\/etc/letsencrypt/live/)<hostname>|\1$2|g" kant-search-stack.yml
sed -i -E "s|(https://)<hostname>|\1$2" kant-search-stack.yml
sed -i -E "s|(domain = )<hostname>|\1$2" config/grafana/grafana.ini
sed -i -E "s|(\"apiUrl\": \")http://localhost:5000|\1https://$2/$3" config/frontend/config.json

# Replace <port> placeholders
sed -i -E "s|<port>|\1$4|g" kant-search-stack.yml
sed -i -E "s|<port>|\1$4" config/reverse-proxy.conf

# Create log directory
mkdir -p log/backend
