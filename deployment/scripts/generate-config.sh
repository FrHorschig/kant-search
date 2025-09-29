#!/bin/bash

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <kant-search version number> <hostname>"
    exit 1
fi

# Download config files for backend and frontend
mkdir -p config/backend config/frontend
curl -L -o config/backend/volume-metadata.json https://github.com/FrHorschig/kant-search-backend/releases/download/$1/volume-metadata.json
curl -L -o config/frontend/config.json https://github.com/FrHorschig/kant-search-frontend/releases/download/$1/config.json
curl -L -o config/frontend/i18n https://github.com/FrHorschig/kant-search-frontend/releases/download/$1/i18n
curl -L -o config/frontend/startpage https://github.com/FrHorschig/kant-search-frontend/releases/download/$1/startpage

# Replace `<hostname>` placeholder
base_domain=$(echo "$2" | awk -F. '{n=NF; print $(n-1)"."$n}')
sed -i -E "s|(\/etc/letsencrypt/live/)<hostname>|\1$base_domain|g" kant-search-stack.yml
sed -i -E "s|(https://)<hostname>|\1$2|g" kant-search-stack.yml
sed -i -E "s|(domain = )<hostname>|\1$2|g" config/grafana/grafana.ini
sed -i -E "s|(\"apiUrl\": \")http://localhost:5000|\1https://$2|g" config/frontend/config.json

# Create log directory
mkdir -p log/backend
