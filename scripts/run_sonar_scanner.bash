#!/bin/bash

analyze_backend() {
    cd kant-search-backend/src
    go test ./... -tags=integration,unit -coverprofile coverage.out 
    cd ../..
    docker run --rm \
        --network=host \
        -e SONAR_HOST_URL="http://localhost:9000" \
        -e SONAR_SCANNER_OPTS="-Dsonar.projectKey=kant-search-backend" \
        -e SONAR_TOKEN="${SONAR_TOKEN_BACKEND}" \
        -v "${KANT_SEARCH_ROOT}/kant-search-backend/src:/usr/src" \
        sonarsource/sonar-scanner-cli
}

analyze_frontend() {
    cd kant-search-frontend/
    ng test --watch=false --code-coverage
    cd ..
    docker run --rm \
        --network=host \
        -e SONAR_HOST_URL="http://localhost:9000" \
        -e SONAR_SCANNER_OPTS="-Dsonar.projectKey=kant-search-frontend -Dsonar.scm.disabled=True" \
        -e SONAR_TOKEN="${SONAR_TOKEN_FRONTEND}" \
        -v "${KANT_SEARCH_ROOT}/kant-search-frontend:/usr/src" \
        sonarsource/sonar-scanner-cli
}

greeting=0
while getopts "gt" opt; do
  case $opt in
    g)
      analyze_backend
      greeting=1
      ;;
    t)
      analyze_frontend
      greeting=1
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
  esac
done

if [ $greeting -eq 0 ]; then
    analyze_backend
    analyze_frontend
fi