#!/bin/bash
set -euo pipefail

NFS_SERVER="192.168.56.20"

echo "[nfs] Instalando NFS client"
apt-get install -y -qq nfs-common

echo "[nfs] Aguardando NFS server em ${NFS_SERVER}"
for i in $(seq 1 20); do
  if showmount -e "${NFS_SERVER}" &>/dev/null; then
    echo "[nfs] NFS server disponivel."
    break
  fi
  echo "[nfs] Tentativa ${i}/20 — aguardando 5s"
  sleep 5
  if [ "$i" -eq 20 ]; then
    echo "[nfs] ERRO: NFS server nao respondeu. Abortando."
    exit 1
  fi
done

echo "[nfs] Montando moodledata"
mkdir -p /var/moodledata
mount -t nfs "${NFS_SERVER}:/var/moodledata" /var/moodledata
chown -R www-data:www-data /var/moodledata

# Persistir no fstab
echo "${NFS_SERVER}:/var/moodledata /var/moodledata nfs defaults,_netdev 0 0" >> /etc/fstab

echo "[nfs] Montagem concluida."
