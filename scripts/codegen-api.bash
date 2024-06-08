#!/bin/bash

# Call this script with the option '-g' to only generate the go server or '-t'
# to only generate the typescript client. Using '-gt' or no option generates
# both.

generate_go_server() {
  rm kant-search-backend/src/kant-search-api-generated -r
  rm kant-search-api/src/generated-server-go -r
  mkdir kant-search-api/src/generated-server-go
  docker run --rm \
      -v "${PWD}:/local" \
      -i /local/kant-search-api/src/openapi/openapi.yaml \
      -o /local/kant-search-api/src/generated-server-go \
      -g go-echo-server \
      openapitools/openapi-generator-cli generate
  cp kant-search-api/src/generated-server-go kant-search-backend/src/kant-search-api-generated -r

  cd kant-search-backend
  LINE="replace github.com/frhorschig/kant-search-api => ./kant-search-api-generated"
  echo "$LINE" > go.mod
  FILE="src/go.mod"
  if ! grep -qF -- "$LINE" "$FILE"; then
    echo "$LINE" >> "$FILE"
  fi
  cd ..
}

generate_ts_client() {
  rm kant-search-api/src/generated-client-ts -r && mkdir kant-search-api/src/generated-client-ts
  docker run --rm \
      -v "${PWD}:/local" \
      -i /local/kant-search-api/src/openapi/openapi.yaml \
      -o /local/kant-search-api/src/generated-client-ts \
      -g typescript-angular \
      -p npmName="@frhorschig/$project"-api \
      -p ngVersion=17.2.2 \
      openapitools/openapi-generator-cli generate

  cd kant-search-api/src/generated-client-ts
  npm install && npm run build
  cd dist
  npm pack

  cd ../../../../kant-search-frontend/
  rm kant-search-api-generated -r
  mkdir kant-search-api-generated
  cp ../kant-search-api/src/generated-client-ts/dist/*.tgz kant-search-api-generated/
  npm install ./kant-search-api-generated/*.tgz
  cd ..
}

greeting=0
while getopts "gt" opt; do
  case $opt in
    g)
      generate_go_server
      greeting=1
      ;;
    t)
      generate_ts_client
      greeting=1
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
  esac
done

if [ $greeting -eq 0 ]; then
  generate_go_server
  generate_ts_client
fi
