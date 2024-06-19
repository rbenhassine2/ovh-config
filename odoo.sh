#!/usr/bin/sh

export DEBIAN_FRONTEND=noninteractive
export NEEDRESTART_MODE=a

#install manually selected deps
sudo apt-get install -y --no-install-recommends pwgen wkhtmltopdf libxml2-dev libpq-dev libjpeg8-dev liblcms2-dev libxslt1-dev zlib1g-dev libsasl2-dev libldap2-dev  libssl-dev libffi-dev  libjpeg-dev libblas-dev libatlas-base-dev

#create odoo user and switch to it
sudo useradd -m -d /opt/odoo -U -r -s /bin/bash odoo
sudo su - odoo

#download odoo 17
git clone https://github.com/odoo/odoo.git --depth 1 --branch 17.0 --single-branch 
cd odoo

mkdir ~/python-venv
python3.10 -m venv ~/python-venv/odoo
source ~/python-venv/odoo/bin/activate
python -m pip install -U pip
python -m pip install wheel
python -m pip install -r requirements.txt
python -m pip install gunicorn "gunicorn[gevent]"

# return to ubuntu sudo 
exit

#install deps that might be missing
sudo sh /opt/odoo/odoo/setup/debinstall.sh

# create odoo conf file
cat <<EOT > odoo.conf
[options]
db_host=localhost
db_port=5432
db_name=odoo_prod
db_user=odoo_user
db_password=`cat .pgpass__odoo_user`
db_sslmode=disable
update=all
workers=23
max_cron_workers=3
logfile = /var/log/odoo.log
log_level = debug
http_interface = 127.0.0.1
http_port = 40000
gevent_port = 40001
x_sendfile
log_web
EOT

sudo mv odoo.conf /etc/
sudo chown odoo:`whoami` /etc/odoo.conf 

# initialize db.
sudo su - odoo
cd odoo
source ~/python-venv/odoo/bin/activate
python odoo-bin -c /etc/odoo.conf -i all &
PID=$!
sleep 20
kill $PID

exit

# create systemd unit file
cat <<EOT > odoo.service
[Unit]
Description=Odoo Service
Requires=postgresql.service
After=network.target postgresql.service

[Service]
Type=simple
SyslogIdentifier=odoo
PermissionsStartOnly=true
User=odoo
Group=odoo
ExecStart=/opt/odoo/python-venv/odoo/bin/python3 /opt/odoo/odoo/odoo-bin -c /etc/odoo.conf
StandardOutput=journal+console

[Install]
WantedBy=multi-user.target
EOT

#enable the systemd unit and start it
mv odoo.service /etc/systemd/system/
sudo systemctl daemon-reload  
sudo systemctl enable --now odoo.service   

cat <<EOT > odoo-nginx.conf
upstream odoo {
  server 127.0.0.1:40000;
}
upstream odoochat {
  server 127.0.0.1:40001;
}
map $http_upgrade $connection_upgrade {
  default upgrade;
  ''      close;
}

map $sent_http_content_type $content_type_csp {
    default "";
    ~image/ "default-src 'none'";
}

server {
    listen 80;
    server_name odoo.rbenhassine.com;
    proxy_read_timeout 720s;
    proxy_connect_timeout 720s;
    proxy_send_timeout 720s;

    # log
    access_log /var/log/nginx/odoo.access.log;
    error_log /var/log/nginx/odoo.error.log;

    # Redirect websocket requests to odoo gevent port
    location /websocket {
        proxy_pass http://odoochat;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection $connection_upgrade;
        proxy_set_header X-Forwarded-Host $http_host;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Real-IP $remote_addr;

        add_header Strict-Transport-Security "max-age=31536000; includeSubDomains";
        proxy_cookie_flags session_id samesite=lax secure;  # requires nginx 1.19.8
    }

    # Redirect requests to odoo backend server
    location / {
        # Add Headers for odoo proxy mode
        proxy_set_header X-Forwarded-Host $http_host;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_redirect off;
        proxy_pass http://odoo;

        add_header Strict-Transport-Security "max-age=31536000; includeSubDomains";
        proxy_cookie_flags session_id samesite=lax secure;  # requires nginx 1.19.8
    }

    location @odoo {
        # Add Headers for odoo proxy mode
        proxy_set_header X-Forwarded-Host $http_host;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_redirect off;
        proxy_pass http://odoo;

        add_header Strict-Transport-Security "max-age=31536000; includeSubDomains";
        proxy_cookie_flags session_id samesite=lax secure;  # requires nginx 1.19.8
    }

    location ~ ^/[^/]+/static/.+$ {
        # root and try_files both depend on your addons paths
        root /opt/odoo/odoo;
        try_files odoo/addons$uri addons$uri @odoo;
        expires 24h;
        add_header Content-Security-Policy $content_type_csp;
    } 

    location /web/filestore {
        internal;
        alias /opt/odoo/.local/share/Odoo/filestore;
    }

    # common gzip
    gzip_types text/css text/scss text/plain text/xml application/xml application/json application/javascript;
    gzip on;
}
EOT

sudo mv odoo-nginx.conf /etc/nginx/sites-available/odoo.conf
sudo ln -s /etc/nginx/sites-available/odoo.conf /etc/nginx/sites-enabled/

sudo systemctl restart nginx.service

sudo certbot --nginx -d odoo.rbenhassine.com