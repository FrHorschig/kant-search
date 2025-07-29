#!/bin/bash

set -e

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <username>"
    exit 1
fi

cd auth/
USERNAME="$1"
PASSWORD=$(tr -dc 'A-Za-z0-9' < /dev/urandom | head -c 64)
htpasswd -cbB htpasswd-admin "$USERNAME" "$PASSWORD"
cd ..

echo "Password for '$USERNAME': $PASSWORD"
