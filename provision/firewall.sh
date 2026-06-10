#!/bin/bash
set -euo pipefail

PROXY_IP="192.168.56.10"

echo "[firewall] Instalando iptables-persistent"
apt-get install -y -qq iptables-persistent

echo "[firewall] Restringindo porta 80 ao proxy (${PROXY_IP})"
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A INPUT -p tcp --dport 80 -s "${PROXY_IP}" -j ACCEPT
iptables -A INPUT -p tcp --dport 80 -j DROP

netfilter-persistent save

echo "[firewall] Concluido."