#!/usr/bin/sh

export DEBIAN_FRONTEND=noninteractive
export NEEDRESTART_MODE=a

sudo add-apt-repository ppa:ondrej/php -y
sudo apt-get update

sudo apt-get install -y --no-install-recommends libpcre3-dev libevent-2.1-7 libevent-core-2.1-7 libevent-dev libossp-uuid16 libossp-uuid-dev
sudo apt-get install -y --no-install-recommends php-pear php8.3 php8.3-amqp php8.3-apcu php8.3-ast php8.3-bcmath php8.3-bz2 php8.3-cgi php8.3-cli php8.3-common php8.3-curl php8.3-dba php8.3-decimal php8.3-dev php8.3-ds php8.3-enchant php8.3-fpm php8.3-gearman php8.3-gmp php8.3-gnupg php8.3-grpc php8.3-http php8.3-igbinary php8.3-imap php8.3-inotify php8.3-intl php8.3-mailparse php8.3-maxminddb php8.3-mbstring php8.3-mcrypt php8.3-memcached php8.3-msgpack php8.3-mysql php8.3-oauth php8.3-opcache php8.3-pcov php8.3-pgsql php8.3-protobuf php8.3-ps php8.3-pspell php8.3-raphf php8.3-rdkafka php8.3-readline php8.3-redis php8.3-rrd php8.3-smbclient php8.3-snmp php8.3-soap php8.3-solr php8.3-sqlite3 php8.3-ssh2 php8.3-stomp php8.3-swoole php8.3-tidy php8.3-uploadprogress php8.3-uuid php8.3-vips php8.3-xhprof php8.3-xml php8.3-xmlrpc php8.3-xsl php8.3-yaml php8.3-zip php8.3-zmq php8.3-zstd

# configure fpm
sudo sed -i "s/^memory_limit.*=.*/memory_limit = 1G/g" /etc/php/8.3/fpm/php.ini
sudo sed -i "s/^post_max_size.*=.*/post_max_size = 220M/g" /etc/php/8.3/fpm/php.ini
sudo sed -i "s/^upload_max_filesize.*=.*/upload_max_filesize = 100M/g" /etc/php/8.3/fpm/php.ini
sudo sed -i "s/^max_file_uploads.*=.*/max_file_uploads = 2/g" /etc/php/8.3/fpm/php.ini
sudo sed -i "s/^;date.timezone.*=.*/date.timezone = UTC/g" /etc/php/8.3/fpm/php.ini

# configure cgi
sudo sed -i "s/^memory_limit.*=.*/memory_limit = 1G/g" /etc/php/8.3/cgi/php.ini
sudo sed -i "s/^post_max_size.*=.*/post_max_size = 220M/g" /etc/php/8.3/cgi/php.ini
sudo sed -i "s/^upload_max_filesize.*=.*/upload_max_filesize = 100M/g" /etc/php/8.3/cgi/php.ini
sudo sed -i "s/^max_file_uploads.*=.*/max_file_uploads = 2/g" /etc/php/8.3/cgi/php.ini
sudo sed -i "s/^;date.timezone.*=.*/date.timezone = UTC/g" /etc/php/8.3/cgi/php.ini

# configure cli
sudo sed -i "s/^memory_limit.*=.*/memory_limit = 512M/g" /etc/php/8.3/cli/php.ini
sudo sed -i "s/^;date.timezone.*=.*/date.timezone = UTC/g" /etc/php/8.3/cli/php.ini

# install phalcon and add it to fpm and cgi
sudo pecl channel-update pecl.php.net
sudo pecl config-set php_ini /etc/php/8.3/cli/php.ini
sudo pecl install phalcon

echo "extension=phalcon.so" | sudo tee /etc/php/8.3/mods-available/phalcon.ini
sudo ln -s /etc/php/8.3/mods-available/phalcon.ini /etc/php/8.3/fpm/conf.d/50-phalcon.ini
sudo ln -s /etc/php/8.3/mods-available/phalcon.ini /etc/php/8.3/cgi/conf.d/50-phalcon.ini
sudo ln -s /etc/php/8.3/mods-available/phalcon.ini /etc/php/8.3/cli/conf.d/50-phalcon.ini

# restart php fpm and nginx
sudo systemctl restart php8.3-fpm.service
sudo systemctl restart nginx.service


# install composer 
# from https://getcomposer.org/download/
EXPECTED_CHECKSUM="$(php8.3 -r 'copy("https://composer.github.io/installer.sig", "php://stdout");')"
php8.3 -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
ACTUAL_CHECKSUM="$(php8.3 -r "echo hash_file('sha384', 'composer-setup.php');")"

if [ "$EXPECTED_CHECKSUM" != "$ACTUAL_CHECKSUM" ]
then
    >&2 echo 'ERROR: Invalid installer checksum'
    rm composer-setup.php
    exit 1
fi

php8.3 composer-setup.php --quiet

rm composer-setup.php

sudo mv composer.phar /usr/local/bin/composer

echo 'export PATH=$PATH:$HOME/.config/composer/vendor/bin' | tee -a ~/.zshrc

# install phalcon devtools
composer global require phalcon/devtools

#install laravel installer
composer global require laravel/installer