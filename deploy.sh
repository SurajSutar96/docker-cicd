#!/bin/bash

APP_NAME="myproject"
APP_DIR="/home/ubuntu/$APP_NAME"
ENV_DIR="$APP_DIR/env"
USER="ubuntu"
SOCK_PATH="/run/gunicorn.sock"

echo "=== Updating system and installing dependencies ==="
sudo apt update
sudo apt install -y python3 python3-pip python3-venv nginx curl git

echo "=== Cloning repository from GitHub ==="
cd ~
git clone https://github.com/yourusername/your-repo.git $APP_DIR

echo "=== Creating virtual environment and installing requirements ==="
python3 -m venv $ENV_DIR
source $ENV_DIR/bin/activate
pip install --upgrade pip
pip install -r $APP_DIR/requirements.txt
pip install gunicorn uvicorn

echo "=== Setting up Gunicorn socket file ==="
sudo bash -c "cat > /etc/systemd/system/gunicorn.socket" <<EOF
[Unit]
Description=gunicorn socket

[Socket]
ListenStream=$SOCK_PATH

[Install]
WantedBy=sockets.target
EOF

echo "=== Setting up Gunicorn service file ==="
sudo bash -c "cat > /etc/systemd/system/gunicorn.service" <<EOF
[Unit]
Description=gunicorn daemon
Requires=gunicorn.socket
After=network.target

[Service]
User=$USER
Group=www-data
WorkingDirectory=$APP_DIR
ExecStart=$ENV_DIR/bin/gunicorn \\
  --access-logfile - \\
  --workers 5 \\
  --bind unix:$SOCK_PATH \\
  --worker-class uvicorn.workers.UvicornWorker \\
  main:app

[Install]
WantedBy=multi-user.target
EOF

echo "=== Reloading systemd and enabling Gunicorn ==="
sudo systemctl daemon-reexec
sudo systemctl daemon-reload
sudo systemctl start gunicorn.socket
sudo systemctl enable gunicorn.socket
sudo systemctl restart gunicorn

echo "=== Setting up Nginx configuration ==="
sudo bash -c "cat > /etc/nginx/sites-available/$APP_NAME" <<EOF
server {
    listen 80;
    server_name _;

    location = /favicon.ico { access_log off; log_not_found off; }

    location / {
        include proxy_params;
        proxy_pass http://unix:$SOCK_PATH;
    }
}
EOF

sudo ln -sf /etc/nginx/sites-available/$APP_NAME /etc/nginx/sites-enabled
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t && sudo systemctl restart nginx

echo "=== Updating UFW firewall rules ==="
sudo ufw delete allow 8000 || true
sudo ufw allow 'Nginx Full'

echo "=== Deployment completed successfully ==="
