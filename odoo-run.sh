#!/usr/bin/sh

export DEBIAN_FRONTEND=noninteractive
export NEEDRESTART_MODE=a

sudo apt-get install -y --no-install-recommends pwgen

################################
# Create odoo postgres user and db
################################
PG_PASS=`pwgen 32 1`
echo $PG_PASS > .pgpass
cat <<EOT > odoo.sql
REVOKE ALL PRIVILEGES ON DATABASE odoo_prod FROM odoo_prod;
DROP USER IF EXISTS odoo_prod;
DROP DATABASE IF EXISTS odoo_prod;

CREATE USER odoo_prod PASSWORD '$PG_PASS';

CREATE DATABASE odoo_prod
WITH
    OWNER = odoo_prod
    IS_TEMPLATE = false
    ALLOW_CONNECTIONS = true
    CONNECTION LIMIT = -1
    TABLESPACE = pg_default
    ENCODING = UTF8;

GRANT ALL PRIVILEGES ON DATABASE odoo_prod TO odoo_prod;
EOT

sudo -u postgres psql < odoo.sql
rm odoo.sql

# create local branch
cd ~/odoo
git checkout -b local

cat <<EOT > default.conf
[options]
db_host=localhost
db_port=5432
db_name=odoo_prod
db_user=odoo_prod
db_password=$PG_PASS
db_sslmode=disable
update=all
EOT

git add .
git commit -am 'add config file'

# create local python environment and 
## instal requirements.txt wheel build deps
sudo apt-get install -y --no-install-recommends libxml2-dev libpq-dev libjpeg8-dev liblcms2-dev libxslt1-dev zlib1g-dev libsasl2-dev libldap2-dev  libssl-dev libffi-dev  libjpeg-dev libblas-dev libatlas-base-dev
mkdir ~/python-venv
python3.10 -m venv ~/python-venv/odoo
source ~/python-venv/odoo/bin/activate
python -m pip install -U pip
python -m pip install wheel
python -m pip install -r requirements.txt