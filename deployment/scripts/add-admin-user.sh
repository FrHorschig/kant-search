#!/bin/bash

set -e

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <path to swarm file> <username>"
    exit 1
fi

SWARM_FILE="$1"
USERNAME="$2"
PASSWORD=$(tr -dc 'A-Za-z0-9' < /dev/urandom | head -c 64)
HASH=$(htpasswd -nbB "$USERNAME" "$PASSWORD" | cut -d ':' -f 2 | sed 's/\$/\$\$/g')
USER_ENTRY="${USERNAME}:${HASH}"

if grep -q 'traefik.http.middlewares.admin-auth.basicauth.users=' "$SWARM_FILE"; then
    EXISTING=$(grep 'traefik.http.middlewares.admin-auth.basicauth.users=' "$SWARM_FILE" | sed 's/.*=//; s/"//g')
    if echo "$EXISTING" | grep -q "$USERNAME:"; then
        echo "User $USERNAME already exists in the label. Aborting."
        exit 1
    fi
    NEW_USERS="${EXISTING},${USER_ENTRY}"
    ESCAPED=$(echo "$NEW_USERS" | sed 's/\//\\\//g')
    if [ -z "$EXISTING" ]; then # append w/o leading comma
        ESCAPED_USER_ENTRY=$(echo "${USER_ENTRY}" | sed 's/[\/&]/\\&/g')
        sed -i -E "s|(traefik.http.middlewares.admin-auth.basicauth.users=)[^\"']*\"|\1${ESCAPED_USER_ENTRY}\"|" "$SWARM_FILE"
    else # append with leading comma
        ESCAPED_USER_ENTRY=$(echo ",${USER_ENTRY}" | sed 's/[\/&]/\\&/g')
        sed -i -E "s|(traefik.http.middlewares.admin-auth.basicauth.users=)([^\"']*)\"|\1\2${ESCAPED_USER_ENTRY}\"|" "$SWARM_FILE"
    fi
else
    echo "Label 'traefik.http.middlewares.admin-auth.basicauth.users=' not found in $SWARM_FILE. Aborting."
    exit 1
fi

echo "Password for '$USERNAME': $PASSWORD"
