#!/bin/bash

set -e
mkdir -p auth

cd auth/
# === generate CA certificate ==================================================
CA_KEY=internal-ca.key
CA_CERT=internal-ca.crt
if [ ! -f $CA_KEY ] || [ ! -f $CA_CERT ]; then
  echo "Generating CA..."
  openssl genrsa -out $CA_KEY 4096
  openssl req -x509 -new -nodes -key $CA_KEY -sha256 -days 3650 -out $CA_CERT -subj "/C=DE/O=kant-search/CN=kant-search"
fi

# === generate application certificates ========================================
generate_cert() {
  local name=$1
  echo "Generating certificate for $name..."

  cat > ${name}.cnf <<EOF
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

  openssl genrsa -out ${name}.key 2048
  openssl req -new -key ${name}.key -out ${name}.csr -config ${name}.cnf
  openssl x509 -req -in ${name}.csr -CA $CA_CERT -CAkey $CA_KEY -CAcreateserial -out ${name}.crt -days 365 -sha256 -extfile ${name}.cnf -extensions v3_req
}

SERVICES=("frontend" "backend" "elasticsearch" "grafana")
for svc in "${SERVICES[@]}"; do
  generate_cert $svc
done

# === generate password for Elasticsearch database =============================
KSDB_PASSWORD=$(tr -dc 'A-Za-z0-9' < /dev/urandom | head -c 64)
echo "$KSDB_PASSWORD" | docker secret create ksdb_password -
