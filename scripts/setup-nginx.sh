#!/bin/bash
set -e

export NEEDRESTART_MODE=a

apt-get -y update
apt-get install -y nginx
systemctl enable nginx

apt-get install -y certbot python3-certbot-nginx
certbot --nginx --register-unsafely-without-email --agree-tos --staging

