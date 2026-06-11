#!/bin/bash
set -euo pipefail

echo "[nfs] Instalando NFS server"
apt-get install -y -qq nfs-kernel-server

echo "[nfs] Configurando export do moodledata"

mkdir -p /var/moodledata
chown -R www-data:www-data /var/moodledata
chmod -R 770 /var/moodledata

EXPORT_LINE="/var/moodledata 192.168.56.0/24(rw,sync,no_subtree_check,no_root_squash)"

if grep -q "^/var/moodledata" /etc/exports; then
  sed -i '\|^/var/moodledata|d' /etc/exports
fi

echo "$EXPORT_LINE" >> /etc/exports

echo "[nfs] Recarregando exports"
exportfs -ua
exportfs -ra

systemctl enable nfs-kernel-server
systemctl restart nfs-kernel-server

echo "[nfs] Export configurado."