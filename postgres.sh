#!/usr/bin/sh

export DEBIAN_FRONTEND=noninteractive
export NEEDRESTART_MODE=a

#install postgres
sudo apt-get install curl ca-certificates -y --no-install-recommends
sudo install -d /usr/share/postgresql-common/pgdg
sudo curl -o /usr/share/postgresql-common/pgdg/apt.postgresql.org.asc --fail https://www.postgresql.org/media/keys/ACCC4CF8.asc
sudo sh -c 'echo "deb [arch=amd64 signed-by=/usr/share/postgresql-common/pgdg/apt.postgresql.org.asc] https://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'

sudo apt-get update
sudo apt-get install postgresql libpq-dev postgresql-contrib -y

#generate password for achieve_superuser
PG_PWD_ACHIEVE_SUPERUSER=`pwgen 32 1`
echo $PG_PWD_ACHIEVE_SUPERUSER > .pgpass__achieve_superuser

#generate password for oddo_user
PG_PWD_ODOO_USER=`pwgen 32 1`
echo $PG_PWD_ODOO_USER > .pgpass__odoo_user

#write the config script to disk
cat <<EOT > pg_config.sql
--DROP achieve_superuser if it exists
DROP USER IF EXISTS achieve_superuser;

--drop odoo_user if it exists
REVOKE ALL PRIVILEGES ON DATABASE odoo_prod FROM odoo_user;
DROP USER IF EXISTS odoo_user;

--drop odoo db if it exists
DROP DATABASE IF EXISTS odoo_prod;

--create users
CREATE USER achieve_superuser SUPERUSER LOGIN PASSWORD '$PG_PWD_ACHIEVE_SUPERUSER';
CREATE USER odoo_user PASSWORD '$PG_PWD_ODOO_USER';

--create odoo_db
CREATE DATABASE odoo_prod
WITH
    OWNER = odoo_user
    IS_TEMPLATE = false
    ALLOW_CONNECTIONS = true
    CONNECTION LIMIT = -1
    TABLESPACE = pg_default
    ENCODING = UTF8;
EOT

sudo -u postgres psql < pg_config.sql
rm pg_config.sql