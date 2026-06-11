#!/bin/bash
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

MOODLE_DIR="/var/www/moodle"
MOODLE_DATA="/var/moodledata"
MOODLE_CACHE="/vagrant/cache/moodle-${MOODLE_VERSION}.tgz"
MOODLE_URL="https://download.moodle.org/download.php/direct/stable405/moodle-${MOODLE_VERSION}.tgz"
PHP_VERSION="8.2"

echo "[moodle] Aguardando PostgreSQL em ${DB_HOST}"
for i in $(seq 1 30); do
  if pg_isready -h "${DB_HOST}" -p 5432 -U "${DB_USER}" -d "${DB_NAME}" -q 2>/dev/null; then
    echo "[moodle] PostgreSQL disponivel."
    break
  fi

  echo "[moodle] Tentativa ${i}/30 — aguardando 5s"
  sleep 5

  if [ "$i" -eq 30 ]; then
    echo "[moodle] ERRO: PostgreSQL nao respondeu. Abortando."
    exit 1
  fi
done

echo "[moodle] Instalando Nginx e PHP ${PHP_VERSION}"
apt-get install -y -qq \
  nginx \
  php${PHP_VERSION}-fpm \
  php${PHP_VERSION}-pgsql \
  php${PHP_VERSION}-xml \
  php${PHP_VERSION}-mbstring \
  php${PHP_VERSION}-curl \
  php${PHP_VERSION}-zip \
  php${PHP_VERSION}-gd \
  php${PHP_VERSION}-intl \
  php${PHP_VERSION}-soap \
  php${PHP_VERSION}-cli \
  php${PHP_VERSION}-opcache

echo "[moodle] Ajustando php.ini"
for PHP_INI in /etc/php/${PHP_VERSION}/fpm/php.ini /etc/php/${PHP_VERSION}/cli/php.ini; do
  sed -i 's/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=1/'             "$PHP_INI"
  sed -i 's/upload_max_filesize = 2M/upload_max_filesize = 128M/' "$PHP_INI"
  sed -i 's/post_max_size = 8M/post_max_size = 128M/'             "$PHP_INI"
  sed -i 's/max_execution_time = 30/max_execution_time = 300/'    "$PHP_INI"
  sed -i 's/memory_limit = 128M/memory_limit = 256M/'             "$PHP_INI"
  sed -i 's/;max_input_vars = 1000/max_input_vars = 5000/'        "$PHP_INI"
done

systemctl enable php${PHP_VERSION}-fpm
systemctl restart php${PHP_VERSION}-fpm


echo "[moodle] Obtendo Moodle ${MOODLE_VERSION}"
mkdir -p /vagrant/cache

if [ ! -f "${MOODLE_CACHE}" ]; then
  echo "[moodle] Baixando tarball (primeira vez)"
  wget -q "$MOODLE_URL" -O "${MOODLE_CACHE}"
else
  echo "[moodle] Usando cache em ${MOODLE_CACHE}."
fi


echo "[moodle] Removendo instalação anterior"
rm -rf "$MOODLE_DIR"

echo "[moodle] Extraindo Moodle"
mkdir -p /var/www

tar xzf "${MOODLE_CACHE}" -C /var/www/

EXTRACTED_DIR=$(find /var/www -maxdepth 1 -type d -name "moodle*" | head -n 1)

if [ -z "$EXTRACTED_DIR" ]; then
  echo "[moodle] ERRO: extração do Moodle falhou"
  exit 1
fi

# evita o clássico "moodle dentro de moodle"
if [[ "$EXTRACTED_DIR" != "$MOODLE_DIR" ]]; then
  mv "$EXTRACTED_DIR" "$MOODLE_DIR"
fi

chown -R www-data:www-data "$MOODLE_DIR"
chmod -R 755 "$MOODLE_DIR"


echo "[moodle] Criando moodledata local"
mkdir -p "$MOODLE_DATA"
chown -R www-data:www-data "$MOODLE_DATA"
chmod -R 770 "$MOODLE_DATA"


echo "[moodle] Aplicando config.php"
sed \
  -e "s/__DB_HOST__/${DB_HOST}/" \
  -e "s/__DB_NAME__/${DB_NAME}/" \
  -e "s/__DB_USER__/${DB_USER}/" \
  -e "s/__DB_PASS__/${DB_PASS}/" \
  -e "s|__WWWROOT__|${MOODLE_WWWROOT}|" \
  /vagrant/config/moodle-config.php > "${MOODLE_DIR}/config.php"

chown www-data:www-data "${MOODLE_DIR}/config.php"
chmod 640 "${MOODLE_DIR}/config.php"


echo "[moodle] Aplicando configuracao Nginx"
cp /vagrant/config/nginx/moodle.conf /etc/nginx/sites-available/moodle
rm -f /etc/nginx/sites-enabled/default
ln -sf /etc/nginx/sites-available/moodle /etc/nginx/sites-enabled/moodle

nginx -t
systemctl enable nginx
systemctl restart nginx


if [ "${IS_PRIMARY}" = "true" ]; then
  echo "[moodle] Instalando banco via CLI (moodle1)"

  cd "$MOODLE_DIR"

  if [ ! -f "config.php" ]; then
    sudo -u www-data php admin/cli/install_database.php \
      --lang="${MOODLE_LANG}" \
      --adminuser="${MOODLE_ADMIN_USER}" \
      --adminpass="${MOODLE_ADMIN_PASS}" \
      --adminemail="${MOODLE_ADMIN_EMAIL}" \
      --fullname="${MOODLE_FULLNAME}" \
      --shortname="${MOODLE_SHORTNAME}" \
      --agree-license

    echo "[moodle] Instalacao concluida."
  else
    echo "[moodle] Moodle já instalado, pulando install."
  fi

else
  echo "[moodle] Aguardando instalacao do moodle1"

  for i in $(seq 1 20); do
    RESULT=$(psql "host=${DB_HOST} dbname=${DB_NAME} user=${DB_USER} password=${DB_PASS}" \
      -tAc "SELECT COUNT(*) FROM information_schema.tables WHERE table_name='mdl_config';" 2>/dev/null || echo "0")

    if [ "$RESULT" = "1" ]; then
      echo "[moodle] Banco pronto. Servidor secundario ok."
      break
    fi

    echo "[moodle] Aguardando moodle1 (${i}/20)"
    sleep 15

    if [ "$i" -eq 20 ]; then
      echo "[moodle] AVISO: timeout aguardando moodle1."
    fi
  done
fi


echo "[moodle] Concluido em ${MOODLE_HOST_IP}."


echo "[moodle] Otimizando PHP-FPM para baixo consumo de memoria"
FPM_POOL="/etc/php/${PHP_VERSION}/fpm/pool.d/www.conf"

sed -i 's/^pm = .*/pm = dynamic/'                     "$FPM_POOL"
sed -i 's/^pm.max_children = .*/pm.max_children = 5/' "$FPM_POOL"
sed -i 's/^pm.start_servers = .*/pm.start_servers = 2/' "$FPM_POOL"
sed -i 's/^pm.min_spare_servers = .*/pm.min_spare_servers = 1/' "$FPM_POOL"
sed -i 's/^pm.max_spare_servers = .*/pm.max_spare_servers = 3/' "$FPM_POOL"

systemctl restart php${PHP_VERSION}-fpm