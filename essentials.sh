#!/usr/bin/sh

export DEBIAN_FRONTEND=noninteractive
export NEEDRESTART_MODE=a

#update the base packages
echo "apt_preserve_sources_list: true" | sudo tee -a /etc/cloud/cloud.cfg
sudo cp /etc/apt/sources.list /etc/apt/sources.list.original
sudo sed -i -e 's/nova.clouds.//g' /etc/apt/sources.list
sudo apt-get update
sudo apt-get upgrade -y
sudo apt-get -y --fix-broken install

#install min dependencies
sudo apt-get install git curl wget build-essential -y
git config --global user.name "Raouf Ben Hassine"
git config --global user.email raouf.ben.hassine.89@gmail.com

#install zsh
sudo apt-get install zsh -y

#install ohmyzsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended --keep-zshrc

git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

sudo chsh -s `which zsh` `whoami`

rm .zshrc

cat <<EOT >> .zshrc
export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="fino"
DISABLE_UNTRACKED_FILES_DIRTY="false"

HIST_STAMPS="yyyy-mm-dd"

plugins=(systemd poetry git aliases alias-finder celery autopep8 python zsh-syntax-highlighting zsh-autosuggestions)

source "$HOME/.oh-my-zsh/oh-my-zsh.sh"
EOT

sudo systemctl reboot