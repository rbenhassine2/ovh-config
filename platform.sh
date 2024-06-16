#!/usr/bin/sh

export DEBIAN_FRONTEND=noninteractive
export NEEDRESTART_MODE=a

sudo add-apt-repository ppa:deadsnakes/ppa -y

sudo apt-get update

#install python 3.8 to 3.13
sudo apt-get install -y python3.8 python3.8-dev python3.8-venv python3.9 python3.9-dev python3.9-venv python3.10 python3.10-dev python3.10-venv python3.11 python3.11-dev python3.11-venv python3.12 python3.12-dev python3.12-venv python3.13 python3.13-dev python3.13-venv --no-install-recommends
sudo apt-get install -y glances --no-install-recommends

#install postgres
sudo apt-get install curl ca-certificates -y --no-install-recommends
sudo install -d /usr/share/postgresql-common/pgdg
sudo curl -o /usr/share/postgresql-common/pgdg/apt.postgresql.org.asc --fail https://www.postgresql.org/media/keys/ACCC4CF8.asc
sudo sh -c 'echo "deb [arch=amd64 signed-by=/usr/share/postgresql-common/pgdg/apt.postgresql.org.asc] https://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'

sudo apt-get update
sudo apt-get install postgresql libpq-dev postgresql-contrib -y

#install nvm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
source ~/.zshrc
nvm install --lts
npm install --global npm@latest