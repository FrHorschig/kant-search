#!/bin/bash

git submodule update --init --recursive

cd kant-search-database
make
cd ..

cd kant-search-backend
go generate ./...
cd src_py
python -m venv .venv
source .venv/bin/activate
pip install -U setuptools wheel spacy
python -m spacy download de_core_news_sm
deactivate
cd ../..

cd kant-search-frontend
npm install
cd ..
