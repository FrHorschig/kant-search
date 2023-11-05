#!/bin/bash

git submodule update --init --recursive
npm install

cd kant-search-api && git checkout main
cd ..

cd kant-search-backend && git checkout main
go generate ./...
cd src_py
python -m venv .venv
source .venv/bin/activate
pip install -U pip setuptools wheel
pip install -U spacy
python -m spacy download de_core_news_sm
deactivate
cd ../..

cd kant-search-database && git checkout main
make
cd ..

cd kant-search-frontend && git checkout main
npm install
cd ..

scripts/api-codegen.bash