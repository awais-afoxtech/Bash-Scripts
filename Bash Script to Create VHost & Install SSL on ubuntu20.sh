#!/bin/bash

# Check if Apache2 is installed
if ! type "apache2" > /dev/null; then
  echo "Apache2 is not installed. Please install Apache2 and try again."
  exit 1
fi

# Check if OpenSSL is installed
if ! type "openssl" > /dev/null; then
  echo "OpenSSL is not installed. Installing OpenSSL..."
  apt-get update
  apt-get install -y openssl
fi

# Set the domain name and document root
read -p "Enter the domain name for the virtual host: " domain
read -p "Enter the document root for the virtual host: " doc_root

# Create the virtual host configuration file
echo "Creating virtual host configuration file..."

cat > /etc/apache2/sites-available/$domain.conf <<EOL
<VirtualHost *:80>
  ServerName $domain
  ServerAdmin webmaster@localhost
  DocumentRoot $doc_root
  ErrorLog \${APACHE_LOG_DIR}/error.log
  CustomLog \${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
EOL

# Enable the virtual host and disable the default host
echo "Enabling virtual host and disabling default host..."
a2ensite $domain.conf
a2dissite 000-default.conf

# Generate a self-signed SSL certificate
echo "Generating self-signed SSL certificate..."
openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/ssl/private/$domain.key -out /etc/ssl/certs/$domain.crt

# Create the SSL virtual host configuration file
echo "Creating SSL virtual host configuration file..."

cat > /etc/apache2/sites-available/$domain-ssl.conf <<EOL
<IfModule mod_ssl.c>
  <VirtualHost *:443>
    ServerName $domain
    ServerAdmin webmaster@localhost
    DocumentRoot $doc_root
    ErrorLog \${APACHE_LOG_DIR}/error.log
    CustomLog \${APACHE_LOG_DIR}/access.log combined
    SSLEngine on
    SSLCertificateFile /etc/ssl/certs/$domain.crt
    SSLCertificateKeyFile /etc/ssl/private/$domain.key
  </VirtualHost>
</IfModule>
EOL

# Enable the SSL virtual host
echo "Enabling SSL virtual host..."
a2ensite $domain-ssl.conf

# Restart Apache2 to apply the changes
echo "Restarting Apache2..."
systemctl restart apache2