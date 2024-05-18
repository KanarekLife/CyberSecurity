#!/bin/bash

export NEEDRESTART_MODE=a

systemctl stop nginx
systemctl disable nginx
apt-get purge -y nginx nginx-common
rm -rf /etc/nginx

certbot delete
apt-get purge -y certbot python3-certbot-nginx
rm -rf /etc/letsencrypt /var/lib/letsencrypt /var/log/letsencrypt

apt autoremove -y