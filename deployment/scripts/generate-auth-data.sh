#!/usr/bin/env bash

set -e
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <admin username>"
    exit 1
fi
ADMIN_USERNAME="$1"
if [[ "$ADMIN_USERNAME" == *:* ]]; then
    echo "Error: admin username must not contain ':'"
    exit 1
fi
create_secret() {
    local name="$1"
    local file="$2"
    docker secret rm "$name" >/dev/null 2>&1 || true
    docker secret create "$name" "$file" >/dev/null
}


# generate secrets for internal tls
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT
chmod 700 "$TMP_DIR"

CA_KEY="$TMP_DIR/internal-ca.key"
CA_CERT="$TMP_DIR/internal-ca.crt"
openssl genrsa \
    -out "$CA_KEY" \
    4096
openssl req \
    -x509 \
    -new \
    -nodes \
    -key "$CA_KEY" \
    -sha256 \
    -days 3650 \
    -out "$CA_CERT" \
    -subj "/C=DE/O=kant-search/CN=kant-search"
create_secret internal_ca_crt "$TMP_DIR/internal-ca.crt"

generate_cert() {
    local name="$1"
    local key="$TMP_DIR/${name}.key"
    local csr="$TMP_DIR/${name}.csr"
    local cert="$TMP_DIR/${name}.crt"
    local cnf="$TMP_DIR/${name}.cnf"
    cat > "$cnf" <<EOF
[ req ]
default_bits       = 2048
prompt             = no
default_md         = sha256
distinguished_name = dn
req_extensions     = v3_req

[ dn ]
C  = DE
O  = kant-search
CN = $name

[ v3_req ]
keyUsage = critical, digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth, clientAuth
subjectAltName = @alt_names

[ alt_names ]
DNS.1 = $name
DNS.2 = localhost
EOF

    openssl genrsa \
        -out "$key" \
        2048
    openssl req \
        -new \
        -key "$key" \
        -out "$csr" \
        -config "$cnf"
    openssl x509 \
        -req \
        -in "$csr" \
        -CA "$CA_CERT" \
        -CAkey "$CA_KEY" \
        -CAcreateserial \
        -out "$cert" \
        -days 365 \
        -sha256 \
        -extfile "$cnf" \
        -extensions v3_req
}

for svc in frontend backend elasticsearch grafana; do
    generate_cert "$svc"
    create_secret "$svc"_crt "$TMP_DIR/"$svc".crt"
    create_secret "$svc"_key "$TMP_DIR/"$svc".key"
done


# Generate Elasticsearch password.
KSDB_PASSWORD="$(tr -dc 'A-Za-z0-9' < /dev/urandom | head -c 64)"
printf '%s' "$KSDB_PASSWORD" > "$TMP_DIR/ksdb_password"
chmod 600 "$TMP_DIR/ksdb_password"
create_secret ksdb_password "$TMP_DIR/ksdb_password"


# generate admin password
USERNAME="$1"
PASSWORD=$(tr -dc 'A-Za-z0-9' < /dev/urandom | head -c 64)

sed -i "s|<admin-username>|$USERNAME|" config/grafana/grafana.ini
sed -i "s|<admin-password>|$PASSWORD|" config/grafana/grafana.ini

htpasswd -cbB "$TMP_DIR"/htpasswd-admin "$USERNAME" "$PASSWORD"
create_secret htpasswd_admin "$TMP_DIR/htpasswd-admin"

echo "Password for '$USERNAME': $PASSWORD"
echo "Write down this password; if you loose it, you have to regenerate it!"