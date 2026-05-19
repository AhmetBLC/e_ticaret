#!/bin/bash
set -e

echo "Updating system..."
sudo apt-get update
sudo DEBIAN_FRONTEND=noninteractive apt-get upgrade -y

echo "Installing Node.js 20..."
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs

echo "Installing Nginx..."
sudo apt-get install -y nginx

echo "Installing PostgreSQL..."
sudo apt-get install -y postgresql postgresql-contrib

echo "Installing PM2..."
sudo npm install -g pm2

echo "Setting up PostgreSQL Database and User..."
# Create a user 'takasapp' with password 'takasapp_pass' and database 'takasapp_db'
sudo -u postgres psql -c "CREATE USER takasapp WITH PASSWORD 'takasapp_pass';" || true
sudo -u postgres psql -c "CREATE DATABASE takasapp_db OWNER takasapp;" || true
sudo -u postgres psql -c "ALTER USER takasapp CREATEDB;" || true

echo "Setup completed successfully."
