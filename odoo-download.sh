#!/usr/bin/sh

export DEBIAN_FRONTEND=noninteractive
export NEEDRESTART_MODE=a

git clone https://github.com/odoo/odoo.git --depth 1
cd odoo
sudo ./setup/debinstall.sh

sudo systemctl reboot