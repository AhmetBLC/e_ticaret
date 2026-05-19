#!/bin/bash
set -e

echo "Updating Nginx Server Name..."
sudo sed -i 's/server_name _;/server_name api.takasapp.info.tr;/' /etc/nginx/sites-available/takasapp
sudo systemctl reload nginx

echo "Installing Certbot..."
sudo snap install core; sudo snap refresh core
sudo snap install --classic certbot
sudo ln -sf /snap/bin/certbot /usr/bin/certbot

echo "Running Certbot for SSL..."
sudo certbot --nginx -d api.takasapp.info.tr --non-interactive --agree-tos -m admin@takasapp.info.tr --redirect

echo "SSL Configuration Completed!"
