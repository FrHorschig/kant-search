#!/bin/bash

project="kant-search"

git submodule update --init --recursive
npm install

cd "$project"-api && git checkout main
cd ..

cd "$project"-backend && git checkout main
cd src_py
python -m venv .venv
source .venv/bin/activate
pip install -U pip setuptools wheel
pip install -U spacy
python -m spacy download de_core_news_sm
deactivate
cd ../..

cd "$project"-database && git checkout main
docker build -f ./deployment/Dockerfile -t "$project"-database .
cd ..

cd "$project"-frontend && git checkout main
npm install
cd ..

scripts/api-codegen.bash