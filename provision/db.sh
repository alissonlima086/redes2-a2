#!/bin/bash
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

echo "[db] Instalando PostgreSQL"
apt-get install -y -qq postgresql postgresql-contrib

systemctl enable postgresql
systemctl start postgresql

echo "[db] Criando usuario e banco"
sudo -u postgres psql <<PSQL
DO \$\$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = '${DB_USER}') THEN
    CREATE ROLE ${DB_USER} WITH LOGIN PASSWORD '${DB_PASS}';
  END IF;
END
\$\$;

CREATE DATABASE ${DB_NAME}
  OWNER ${DB_USER}
  ENCODING 'UTF8'
  LC_COLLATE 'en_US.UTF-8'
  LC_CTYPE 'en_US.UTF-8'
  TEMPLATE template0;

GRANT ALL PRIVILEGES ON DATABASE ${DB_NAME} TO ${DB_USER};
PSQL

echo "[db] Configurando acesso remoto"
PG_VERSION=$(psql --version | grep -oP '\d+' | head -1)
PG_CONF="/etc/postgresql/${PG_VERSION}/main/postgresql.conf"
PG_HBA="/etc/postgresql/${PG_VERSION}/main/pg_hba.conf"

sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/" "$PG_CONF"

echo "host  all  all  192.168.56.0/24  scram-sha-256" >> "$PG_HBA"

systemctl restart postgresql

echo "[db] Concluido."
