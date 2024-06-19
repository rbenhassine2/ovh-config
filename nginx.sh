#!/usr/bin/sh

export DEBIAN_FRONTEND=noninteractive
export NEEDRESTART_MODE=a

sudo add-apt-repository ppa:ondrej/nginx-mainline -y

#install nginx and certbot 
sudo apt-get install --no-install-recommends nginx-extras certbot python3-certbot-nginx python3-certbot-dns-ovh -y 

sudo rm /etc/nginx/sites-enabled/default
sudo rm /etc/nginx/sites-available/default

cat <<EOT >> default
server {
    listen 80 default_server;
    listen [::]:80 default_server ipv6only=on;

    server_name rbenhassine.com;

    root /var/www/html;
    index index.html index.htm index.nginx-debian.html;

    location / {
        try_files $uri $uri/ =404;
    }
}
EOT

sudo cp default /etc/nginx/sites-available/default
sudo ln -s /etc/nginx/sites-available/default /etc/nginx/sites-enabled

#this command needs to be observed
sudo certbot --nginx -d rbenhassine.com