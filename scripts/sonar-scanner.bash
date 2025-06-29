#!/bin/bash

SONAR_PORT=8000
SONAR_VERSION=9.9.8-community
SCANNER_VERSION=latest

SONAR_ADMIN_USER="admin"
SONAR_ADMIN_OLD_PASSWORD="admin"
SONAR_ADMIN_NEW_PASSWORD="adminnew"

# === option -s: start the SonarQube container =================================
start_sonar_container() {
    VOLUME_NAME="sonarqube_data"
    docker volume create $VOLUME_NAME
    
    CONTAINER_NAME="sonarqube"
    docker stop $CONTAINER_NAME
    docker rm $CONTAINER_NAME
    docker volume rm $VOLUME_NAME

    docker pull sonarqube:$SCANNER_VERSION
    docker run -d --name "$CONTAINER_NAME" \
      -e SONAR_ES_BOOTSTRAP_CHECKS_DISABLE=true \
      -v sonarqube_data:/opt/sonarqube/ \
      -p $SONAR_PORT:9000 \
      sonarqube:$SONAR_VERSION

    wait_for_sonar
    change_admin_password
    recreate_env

    SONAR_TOKEN_BACKEND=$(create_project "kant-search-backend" "Kant Search Backend" "backend-token")
    SONAR_TOKEN_FRONTEND=$(create_project "kant-search-frontend" "Kant Search Frontend" "frontend-token")
    echo "SONAR_TOKEN_BACKEND=$SONAR_TOKEN_BACKEND" >> .env
    echo "SONAR_TOKEN_FRONTEND=$SONAR_TOKEN_FRONTEND" >> .env
    echo "Done."
}

wait_for_sonar() {
    local admin_auth="${SONAR_ADMIN_USER}:${SONAR_ADMIN_OLD_PASSWORD}"
    until curl -s -u "$admin_auth" "http://localhost:$SONAR_PORT/api/system/health" | grep -q '"health":"GREEN"'; do
        sleep 5
        echo "waiting..."
    done
}

change_admin_password() {
    echo "Changing default admin password..."
    curl -s -u "$SONAR_ADMIN_USER:$SONAR_ADMIN_OLD_PASSWORD" -X POST \
      "http://localhost:$SONAR_PORT/api/users/change_password" \
      -d "login=$SONAR_ADMIN_USER" \
      -d "previousPassword=$SONAR_ADMIN_OLD_PASSWORD" \
      -d "password=$SONAR_ADMIN_NEW_PASSWORD"
}

recreate_env() {
    if [ -f .env ]; then
        existing_root=$(grep '^KANT_SEARCH_ROOT=' .env | cut -d '=' -f2- | tr -d '"')
    fi

    if [ -z "$existing_root" ]; then
        read -rp "Enter the absolute path to KANT_SEARCH_ROOT: " input_path
        if [ ! -d "$input_path" ]; then
            echo "Warning: The path '$input_path' does not exist or is not a directory."
        fi
        KANT_SEARCH_ROOT="$input_path"
    else
        KANT_SEARCH_ROOT="$existing_root"
    fi

    echo "KANT_SEARCH_ROOT=\"$KANT_SEARCH_ROOT\"" > .env
}

create_project() {
    local project_key=$1
    local project_name=$2
    local token_name=$3
    local admin_auth="${SONAR_ADMIN_USER}:${SONAR_ADMIN_NEW_PASSWORD}"

    if ! curl -s -u "$admin_auth" "http://localhost:$SONAR_PORT/api/projects/search?projects=$project_key" | grep -q "\"key\":\"$project_key\""; then
        curl -s -u "$admin_auth" -X POST \
          "http://localhost:$SONAR_PORT/api/projects/create?project=$project_key&name=$project_name" >&2
    fi

    curl -s -u "$admin_auth" -X POST \
      "http://localhost:$SONAR_PORT/api/user_tokens/revoke" \
      -d "name=$token_name" >&2
    local token_json=$(curl -s -u "$admin_auth" -X POST \
        "http://localhost:$SONAR_PORT/api/user_tokens/generate" \
        -d "name=$token_name")

    local token=$(echo "$token_json" | jq -r '.token')

    if [ -z "$token" ] || [ "$token" == "null" ]; then
        echo "Error: Failed to retrieve token for project '$project_key'." >&2
        echo "Response: $token_json" >&2
        return 1
    fi

    echo "$token"
}

# === option -g: analyze the backend ===========================================
analyze_backend() {
    source .env
    cd kant-search-backend/src
    go test ./... -tags=integration,unit -coverprofile coverage.out
    mkdir -p .sonar/cache .scannerwork && chmod -R 777 .sonar .scannerwork
    cd ../..
    docker pull sonarsource/sonar-scanner-cli:$SCANNER_VERSION
    docker run --rm \
        --network=host \
        -e SONAR_HOST_URL="http://localhost:$SONAR_PORT" \
        -e SONAR_USER_HOME=".sonar" \
        -e SONAR_SCANNER_OPTS="-Dsonar.projectKey=kant-search-backend" \
        -e SONAR_TOKEN="${SONAR_TOKEN_BACKEND}" \
        -v "${KANT_SEARCH_ROOT}/kant-search-backend/src:/usr/src" \
        sonarsource/sonar-scanner-cli:$SCANNER_VERSION
}

# === option -t: analyze the frontend ==========================================
analyze_frontend() {
    source .env
    cd kant-search-frontend/
    ng test --watch=false --code-coverage --browsers=ChromeHeadless
    mkdir -p .sonar/cache .scannerwork && chmod -R 777 .sonar .scannerwork
    cd ..
    docker pull sonarsource/sonar-scanner-cli:$SCANNER_VERSION
    docker run --rm \
        --network=host \
        -e SONAR_HOST_URL="http://localhost:$SONAR_PORT" \
        -e SONAR_USER_HOME=".sonar" \
        -e SONAR_SCANNER_OPTS=" \
            -Dsonar.projectKey=kant-search-frontend \
            -Dsonar.scm.disabled=true \
            -Dsonar.javascript.lcov.reportPaths=coverage/lcov.info" \
        -e SONAR_TOKEN="${SONAR_TOKEN_FRONTEND}" \
        -v "${KANT_SEARCH_ROOT}/kant-search-frontend:/usr/src" \
        sonarsource/sonar-scanner-cli:$SCANNER_VERSION
}

greeting=0
while getopts "sgt" opt; do
  case $opt in
    s)
      start_sonar_container
      greeting=1
      ;;
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
    echo "Use option '-s' to start the SonarQube container, '-g' to analyze the backend and '-t' to analyze the frontend."
fi
