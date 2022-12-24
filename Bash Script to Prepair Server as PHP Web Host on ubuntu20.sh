#!/bin/bash

# Set the script to exit on error and treat unset variables as errors
set -e
set -u

# Update package manager and install necessary packages
sudo apt-get update
sudo apt-get install -y software-properties-common

# Install the necessary dependencies for MySQL
sudo apt-get install -y mysql-server libmysqlclient-dev

# Add the PHP 8.1 PPA and update the package list
sudo add-apt-repository -y ppa:ondrej/php
sudo apt-get update

# Install a specific version of PHP and necessary extensions
sudo apt-get install -y \
  php8.1-cli=8.1* \
  php8.1-fpm=8.1* \
  php8.1-common=8.1* \
  php8.1-mysql=8.1* \
  php8.1-xml=8.1* \
  php8.1-mbstring=8.1* \
  php8.1-curl=8.1* \
  php8.1-gd=8.1* \
  php8.1-intl=8.1* \
  php8.1-json=8.1* \
  php8.1-bcmath=8.1* \
  php8.1-zip=8.1* \
  php-imagick=8.1*

# Restart the PHP FastCGI Process Manager (php-fpm)
sudo systemctl restart php8.1-fpm

# Enable the Apache HTTP/2 module
sudo a2enmod http2

# Configure Apache to serve HTTP/2 traffic
echo "Protocols h2 h2c http/1.1" | sudo tee /etc/apache2/mods-available/http2.conf

# Enable the Apache SSL module
sudo a2enmod ssl

# Enable the Apache proxy modules
sudo a2enmod proxy
sudo a2enmod proxy_http
sudo a2enmod xml2enc

# Restart the Apache web server to apply the changes
sudo systemctl restart apache2

# Enable the Apache web server to automatically start on server reboot
sudo systemctl enable apache2

# Secure the MySQL installation
sudo systemctl start mysql

# Enable the MySQL server to automatically start on server reboot
sudo systemctl enable mysql

# Secure the MySQL installation
sudo mysql_secure_installation
# sudo mysql -u root -p'password' -e "
#   ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY 'password';
#   DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
#   FLUSH PRIVILEGES;
# "

# Enable remote access to MySQL
sudo mysql -u root -p'password' -e "
  GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY 'password' WITH GRANT OPTION;
  FLUSH PRIVILEGES;
"

# Restart the MySQL service to apply the changes
systemctl restart mysql

# Install Redis and enable remote access
sudo sed -i 's/bind 127.0.0.1/bind 0.0.0.0/' /etc/redis/redis.conf
sudo systemctl restart redis-server

# Enable the Redis server to automatically start on server reboot
sudo systemctl enable redis-server

# Set up a firewall to allow incoming traffic on the HTTP and HTTPS ports
sudo apt install ufw -y
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 6379/tcp
sudo ufw enable

# Install nvm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.37.2/install.sh | bash

# Activate nvm
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm

# Install a specific version of Node.js
nvm install 14

# Set the specific version of Node.js as the default
nvm alias default node

# Install Node.js, npm, Yarn, and PM2
sudo apt-get install -y nodejs yarn pm2

# Enable npm, Yarn, and PM2 for the sudo command
echo "Updating the sudoers file to allow npm, yarn, and pm2 to be run with sudo"
echo "Enter the password for the current user when prompted"
sudo visudo -f /etc/sudoers.d/enable-sudo-npm-yarn-pm2 <<EOF

# Allow npm, yarn, and pm2 to be run with sudo
Cmnd_Alias NPM = /usr/bin/npm
Cmnd_Alias YARN = /usr/bin/yarn
Cmnd_Alias PM2 = /usr/local/bin/pm2

%sudo ALL=(ALL) NOPASSWD: NPM, YARN, PM2
EOF
# sudo visudo -c

# Link the nodejs binary to node, so it can be run with the node command
sudo ln -s /usr/bin/nodejs /usr/bin/node

# Enable the PM2 process manager to automatically start on server reboot
sudo env PATH=$PATH:/usr/
pm2 startup