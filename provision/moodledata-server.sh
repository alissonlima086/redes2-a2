#!/bin/bash
set -euo pipefail

echo "[nfs] Instalando NFS server"
apt-get install -y -qq nfs-kernel-server

echo "[nfs] Configurando export do moodledata"
mkdir -p /var/moodledata
chown -R www-data:www-data /var/moodledata
chmod -R 770 /var/moodledata

# Exporta para toda a rede interna
echo "/var/moodledata 192.168.56.0/24(rw,sync,no_subtree_check,no_root_squash)" >> /etc/exports

exportfs -ra
systemctl enable nfs-kernel-server
systemctl restart nfs-kernel-server

echo "[nfs] Export configurado."
