#!/bin/bash
# Запускать на чистом Ubuntu 22.04/24.04 Server от root

set -e

DOMAIN="company.local"
NETBIOS="COMPANY"
ADMIN_PASS="P@ssw0rd!"
SERVER_IP=$(hostname -I | awk '{print $1}')

hostnamectl set-hostname ad.$DOMAIN
echo "$SERVER_IP ad.$DOMAIN ad" >> /etc/hosts

systemctl disable --now systemd-resolved
rm -f /etc/resolv.conf
echo "nameserver 127.0.0.1" > /etc/resolv.conf

export DEBIAN_FRONTEND=noninteractive
apt update
apt install -y samba krb5-config krb5-user winbind smbclient dnsutils

mv /etc/samba/smb.conf /etc/samba/smb.conf.bak 2>/dev/null || true

samba-tool domain provision \
  --use-rfc2307 \
  --server-role=dc \
  --realm=$(echo "$DOMAIN" | tr '[:lower:]' '[:upper:]') \
  --domain=$NETBIOS \
  --dns-backend=SAMBA_INTERNAL \
  --adminpass="$ADMIN_PASS" \
  --host-ip="$SERVER_IP" \
  --interactive=no

systemctl unmask samba-ad-dc
systemctl enable --now samba-ad-dc

REALM="DC=$(echo $DOMAIN | sed 's/\./,DC=/g')"
samba-tool ou create "OU=Финансы,$REALM"
samba-tool ou create "OU=Продажи,$REALM"
samba-tool ou create "OU=Администраторы,$REALM"

samba-tool group add Финансы
samba-tool group add Продажи
samba-tool group add Администраторы

echo "Samba AD развёрнут"
echo "Домен: $DOMAIN"
echo "Администратор: administrator / $ADMIN_PASS"
echo "IP сервера: $SERVER_IP"
echo "Теперь подключите клиентов к домену $DOMAIN"
