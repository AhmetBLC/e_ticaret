#!/bin/bash
set -e

cd ~/e_ticaret

echo "Creating .env file..."
cat > .env << EOL
PORT=3000
NODE_ENV=production
DATABASE_URL=postgres://takasapp:takasapp_pass@localhost:5432/takasapp_db
DATABASE_SSL=false
JWT_SECRET=super-secret-jwt-key-takasapp-2026-production
JWT_EXPIRES_IN=7d
BCRYPT_ROUNDS=12
CORS_ORIGIN=*
EOL

echo "Installing npm dependencies..."
npm install --omit=dev

echo "Initializing database..."
# Some scripts might fail if tables already exist, ignoring errors for now.
node scripts/ensure-users-table.js || true
node scripts/ensure-catalog-tables.js || true
node scripts/ensure-order-tracking.js || true

echo "Starting app with PM2..."
pm2 start src/server.js --name "takasapp-api" --update-env
pm2 save
pm2 startup | tail -n 1 > pm2_startup.sh
sudo bash pm2_startup.sh || true

echo "Configuring Nginx..."
sudo cat > /etc/nginx/sites-available/takasapp << EOL
server {
    listen 80;
    listen [::]:80;
    server_name _;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOL

sudo ln -sf /etc/nginx/sites-available/takasapp /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default
sudo systemctl restart nginx

echo "Deployment completed successfully!"
