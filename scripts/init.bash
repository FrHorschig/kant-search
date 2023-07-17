#!/bin/bash

project="kant-search"

git submodule update --init --recursive
npm install

cd "$project"-api && git checkout main
cd ..

cd "$project"-backend && git checkout main
cd ..

cd "$project"-database && git checkout main
docker build -f ./deployment/Dockerfile -t "$project"-database .
cd ..

cd "$project"-frontend && git checkout main
npm install
cd ..

scripts/api-codegen.bash