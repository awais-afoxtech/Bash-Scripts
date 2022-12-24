#!/bin/bash

# Update package manager and install necessary packages
sudo apt-get update
sudo apt-get install -y software-properties-common

sudo add-apt-repository -y ppa:ondrej/php
sudo apt-get update

sudo wget https://dev.mysql.com/get/mysql-apt-config_0.8.15-1_all.deb
sudo dpkg -i mysql-apt-config_0.8.15-1_all.deb
sudo apt-get update

sudo apt-get install -y git composer mysql-server redis-server apache2 libapache2-mod-php imagemagick libapache2-mod-proxy-html libxml2-dev

# Install PHP 8.1 and necessary extensions
sudo apt-get install -y php8.1-cli php8.1-fpm php8.1-common php8.1-mysql php8.1-xml php8.1-mbstring php8.1-curl php8.1-gd php8.1-intl php8.1-json php8.1-bcmath php8.1-zip php-imagick -y

systemctl restart php8.1-fpm

# Enable the Apache HTTP/2 module
sudo a2enmod http2

# the default SSL certificate
sudo a2enmod ssl
sudo a2ssl-certificate
sudo a2enmod proxy
sudo a2enmod proxy_http
sudo a2enmod xml2enc

# Restart the Apache web server to apply the changes
sudo systemctl restart apache2

# Enable the Apache web server to automatically start on server reboot
sudo systemctl enable apache2

# enable remote access
sudo mysql --user=root mysql
ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY 'password';
GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION;
FLUSH PRIVILEGES;
exit

# enable remote access
# sudo mysql -e "GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY 'password' WITH GRANT OPTION;"

# Enable the MySQL server to automatically start on server reboot
sudo systemctl enable mysql

# Install Redis and enable remote access
sudo sed -i 's/bind 127.0.0.1/bind 0.0.0.0/' /etc/redis/redis.conf
sudo systemctl restart redis-server

# Enable the Redis server to automatically start on server reboot
sudo systemctl enable redis-server

# Set up a firewall to allow incoming traffic on the HTTP and HTTPS ports
sudo apt install ufw -y
sudo ufw allow 80
sudo ufw allow 443
sudo ufw enable

# Install nvm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.37.2/install.sh | bash

# Activate nvm
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm

# Install the latest LTS version of Node.js
nvm install --lts

# Set the latest LTS version of Node.js as the default
nvm alias default node

# Install Node.js, npm, Yarn, and PM2
sudo apt install nodejs yarn pm2 -y

# Enable npm, Yarn, and PM2 for the sudo command
sudo visudo -c

# Link the nodejs binary to node, so it can be run with the node command
sudo ln -s /usr/bin/nodejs /usr/bin/node

# Enable the PM2 process manager to automatically start on server reboot
pm2 startup

