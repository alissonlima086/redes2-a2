#!/bin/bash
set -euo pipefail

PROXY_IP="192.168.56.10"

echo "[firewall] Instalando iptables-persistent"
apt-get install -y -qq iptables-persistent

HOSTNAME=$(hostname)

echo "[firewall] Host detectado: $HOSTNAME"

iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

if [ "$HOSTNAME" = "moodle1" ] || [ "$HOSTNAME" = "moodle2" ] || [ "$HOSTNAME" = "moodle3" ]; then
  echo "[firewall] Aplicando regra de BACKEND (Moodle)"

  iptables -A INPUT -p tcp --dport 80 -s "${PROXY_IP}" -j ACCEPT
  iptables -A INPUT -p tcp --dport 80 -j DROP

else
  echo "[firewall] Proxy ou DB: sem restrição de HTTP"

  iptables -A INPUT -p tcp --dport 80 -j ACCEPT
  iptables -A INPUT -p tcp --dport 8080 -j ACCEPT
fi

netfilter-persistent save

echo "[firewall] Concluido."