#!/bin/bash

echo "Deleting old app"
sudo rm -rf /var/www/langchain-app

echo "Creating app folder"
sudo mkdir -p /var/www/langchain-app

echo "Moving files to app folder"
sudo cp -r * /var/www/langchain-app

# Navigate to the app directory
cd /var/www/langchain-app/
sudo mv env .env

echo "Installing Python and pip"
sudo apt-get update
sudo apt-get install -y python3 python3-pip

echo "Installing dependencies"
sudo pip3 install -r requirements.txt
sudo pip3 install "uvicorn[standard]" gunicorn

# Install and configure Nginx
if ! command -v nginx > /dev/null; then
    echo "Installing Nginx"
    sudo apt-get install -y nginx
fi

# Update Nginx config
if [ ! -f /etc/nginx/sites-available/langchain-app ]; then
    sudo rm -f /etc/nginx/sites-enabled/default
    sudo bash -c 'cat > /etc/nginx/sites-available/langchain-app <<EOF
server {
    listen 80;
    server_name _;

    location / {
        proxy_pass http://unix:/var/www/langchain-app/myapp.sock;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF'
    sudo ln -s /etc/nginx/sites-available/langchain-app /etc/nginx/sites-enabled/
fi

echo "Restarting Nginx"
sudo systemctl restart nginx

# Stop old Gunicorn processes
sudo pkill gunicorn || true
sudo rm -f myapp.sock

# Start FastAPI using Gunicorn + Uvicorn worker
echo "Starting FastAPI app with Gunicorn"
sudo gunicorn main:app \
  --workers 3 \
  --worker-class uvicorn.workers.UvicornWorker \
  --bind unix:/var/www/langchain-app/myapp.sock \
  --user www-data \
  --group www-data \
  --daemon

echo "✅ FastAPI app deployed and accessible at: http://18.118.31.182/"
