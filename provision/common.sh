#!/bin/bash
set -euo pipefail

echo "[common] Configurando locale e timezone"
export DEBIAN_FRONTEND=noninteractive
sed -i 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
locale-gen
echo 'LANG=en_US.UTF-8' > /etc/default/locale
timedatectl set-timezone America/Sao_Paulo

echo "[common] Atualizando pacotes base"
apt-get update -qq
apt-get install -y -qq \
  curl \
  wget \
  git \
  vim \
  net-tools \
  iputils-ping \
  dnsutils \
  htop \
  unzip \
  ca-certificates \
  gnupg \
  postgresql-client

echo "[common] Configurando /etc/hosts para resolucao interna"
cat >> /etc/hosts << 'HOSTS'

# Ambiente redes2
192.168.56.10  proxy
192.168.56.20  moodle1
192.168.56.30  moodle2
192.168.56.40  moodle3
192.168.56.50  db
HOSTS

echo "[common] Executando firewall"
bash /vagrant/provision/firewall.sh

echo "[common] Concluido."