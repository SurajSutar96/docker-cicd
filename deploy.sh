#!/bin/bash

echo "Deleting old app"
sudo rm -rf /var/www/

echo "Creating app folder"
sudo mkdir -p /var/www/langchain-app 

echo "Moving files to app folder"
sudo mv * /var/www/langchain-app

# Navigate to the app directory
cd /var/www/langchain-app/
sudo mv env .env

echo "Installing Python and pip"
sudo apt-get update
sudo apt-get install -y python3 python3-pip

# Install application dependencies
echo "Installing dependencies"
sudo pip3 install -r requirements.txt

# Install Uvicorn and Gunicorn for FastAPI
sudo pip3 install "uvicorn[standard]" gunicorn

# Install and configure Nginx
if ! command -v nginx > /dev/null; then
    echo "Installing Nginx"
    sudo apt-get install -y nginx
fi

# Nginx reverse proxy config
if [ ! -f /etc/nginx/sites-available/myapp ]; then
    sudo rm -f /etc/nginx/sites-enabled/default
    sudo bash -c 'cat > /etc/nginx/sites-available/myapp <<EOF
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
    sudo ln -s /etc/nginx/sites-available/myapp /etc/nginx/sites-enabled
    sudo systemctl restart nginx
else
    echo "Nginx reverse proxy configuration already exists."
fi

# Stop existing Gunicorn process
sudo pkill gunicorn || true
sudo rm -f myapp.sock

# Start Gunicorn with Uvicorn worker for FastAPI
# Replace 'main:app' if your FastAPI app uses a different file/module
echo "Starting FastAPI with Gunicorn + Uvicorn workers"
sudo gunicorn main:app --workers 3 --worker-class uvicorn.workers.UvicornWorker --bind unix:myapp.sock --user www-data --group www-data --daemon

echo "FastAPI app deployed and running! 🚀"