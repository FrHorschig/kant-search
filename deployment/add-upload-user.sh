#!/bin/bash

set -e
mkdir -p auth
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <username for the upload endpoint>"
    exit 1
fi

cd auth/
USERNAME="$1"
UPLOAD_PASSWORD=$(tr -dc 'A-Za-z0-9' < /dev/urandom | head -c 64)
htpasswd -cbB htpasswd-upload "$USERNAME" "$UPLOAD_PASSWORD"
cd ..
echo "Password for the upload endpoint: $UPLOAD_PASSWORD"