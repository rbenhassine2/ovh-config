#!/usr/bin/sh

export DEBIAN_FRONTEND=noninteractive
export NEEDRESTART_MODE=a

[ -e .ovh.ini ] && rm -- .ovh.ini

cat <<EOT >> .ovh.ini
dns_ovh_endpoint = $1
dns_ovh_application_key = $2
dns_ovh_application_secret = $3
dns_ovh_consumer_key = $4
EOT

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

sudo certbot --nginx -d rbenhassine.com