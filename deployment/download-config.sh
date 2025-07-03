#!/bin/bash

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <kant-search version number>"
    exit 1
fi

mkdir -p config/backend config/frontend
curl -L -o config/backend/volume-metadata.json https://github.com/FrHorschig/kant-search-backend/releases/download/$1/volume-metadata.json
curl -L -o config/frontend/config.json https://github.com/FrHorschig/kant-search-frontend/releases/download/$1/config.json

mkdir elastic-data
