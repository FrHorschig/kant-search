#!/bin/bash

git submodule update --init --recursive

cd kant-search-backend
go install github.com/golang/mock/mockgen@v1.6.0
go install github.com/cortesi/modd/cmd/modd@latest
go mod tidy
go generate ./...
cd ..

cd kant-search-frontend
npm install
cd ..
