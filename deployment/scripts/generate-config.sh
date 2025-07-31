#!/bin/bash

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <kant-search version number> <hostname>"
    exit 1
fi

mkdir -p config/backend config/frontend
curl -L -o config/backend/volume-metadata.json https://github.com/FrHorschig/kant-search-backend/releases/download/$1/volume-metadata.json
curl -L -o config/frontend/config.json https://github.com/FrHorschig/kant-search-frontend/releases/download/$1/config.json

sed -i -E \
  -e "s|(\/etc/letsencrypt/live/)<hostname>|\1$2|g" \
  -e "s|(https://)<hostname>|\1$2|g" \
  kant-search-stack.yml
sed -i -E "s|(domain = )<hostname>|\1$2|g" config/grafana/grafana.ini
sed -i -E "s|(\"apiUrl\": \")http://localhost:5000|\1https://$2|g" config/frontend/config.json