#!/bin/bash
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

echo "[proxy] Instalando Nginx"
apt-get install -y -qq nginx

echo "[proxy] Aplicando configuracao"
cp /vagrant/config/nginx/proxy.conf /etc/nginx/sites-available/proxy
rm -f /etc/nginx/sites-enabled/default
ln -sf /etc/nginx/sites-available/proxy /etc/nginx/sites-enabled/proxy

nginx -t
systemctl enable nginx
systemctl restart nginx

echo "[proxy] Concluido. Acesse http://192.168.56.10"
