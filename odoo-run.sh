#!/usr/bin/sh

export DEBIAN_FRONTEND=noninteractive
export NEEDRESTART_MODE=a

# create local branch
cd ~/odoo
git checkout -b local

# create local python environment and 
## instal requirements.txt wheel build deps
sudo apt-get install libxml2-dev libpq-dev libjpeg8-dev liblcms2-dev libxslt1-dev zlib1g-dev libsasl2-dev libldap2-dev  libssl-dev libffi-dev  libjpeg-dev libblas-dev libatlas-base-dev -y
mkdir ~/python-venv
python3.10 -m venv ~/python-venv/odoo
source ~/python-venv/odoo/bin/activate
python -m pip install -U pip
python -m pip install
python -m pip install -r requirements.txt