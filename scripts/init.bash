#!/bin/bash

git submodule update --init --recursive

cd kant-search-backend
go generate ./...
cd ..

cd kant-search-frontend
npm install
cd ..
