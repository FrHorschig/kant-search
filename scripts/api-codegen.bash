#!/bin/bash

# Call this script with the option '-g' to only generate the go server or '-t'
# to only generate the typescript client. Using '-gt' or no option generates
# both.

project="kant-search"
userid="FrHorschig"

generate_go_server() {
  rm "$project"-backend/src/"$project"-api-generated -r
  rm "$project"-api/src/generated-server-go -r
  mkdir "$project"-api/src/generated-server-go 
  docker run --rm \
      -v "${PWD}:/local" \
      openapitools/openapi-generator-cli generate \
      -i /local/"$project"-api/src/openapi/openapi.yaml \
      -o /local/"$project"-api/src/generated-server-go \
      -g go-echo-server \
      --git-user-id="$userid" \
      --git-repo-id="$project"-api
  cp "$project"-api/src/generated-server-go "$project"-backend/src/"$project"-api-generated -r
  LINE="replace github.com/"$userid"/"$project"-api => ./"$project"-api-generated"
  FILE=""$project"-backend/src/go.mod"
  if ! grep -qF -- "$LINE" "$FILE"; then
    echo "$LINE" >> "$FILE"
  fi
}


generate_ts_client() {
  rm "$project"-api/src/generated-client-ts -r && mkdir "$project"-api/src/generated-client-ts
  docker run --rm \
      -v "${PWD}:/local" \
      openapitools/openapi-generator-cli generate \
      -i /local/"$project"-api/src/openapi/openapi.yaml \
      -o /local/"$project"-api/src/generated-client-ts \
      -g typescript-angular \
      -p npmName="@frhorschig/$project"-api \
      -p ngVersion=15.2.0 \
      --git-user-id="$userid" \
      --git-repo-id="$project"-api
  cd "$project"-api/src/generated-client-ts
  npm install && npm run build
  cd dist
  npm pack
  cd ../../../../"$project"-frontend/
  rm "$project"-api-generated -r
  mkdir "$project"-api-generated
  cp ../"$project"-api/src/generated-client-ts/dist/*.tgz "$project"-api-generated/
  npm install ./"$project"-api-generated/*.tgz
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
