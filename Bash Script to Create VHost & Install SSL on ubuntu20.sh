#!/bin/bash

# Set the script to exit if any commands fail
set -e
set -o pipefail

# Check if Apache2 is installed
if ! which apache2 > /dev/null; then
  echo "Apache2 is not installed. Please install Apache2 and try again."
  exit 1
fi

# Check if OpenSSL is installed
if ! which openssl > /dev/null; then
  echo "OpenSSL is not installed. Installing OpenSSL..."
  apt update
  apt install -y openssl
fi

# Enable the SSL module for Apache
a2enmod ssl

# Set the domain name and document root
read -r -p "Enter the domain name for the virtual host: " -t 180 domain
read -r -p "Enter the document root for the virtual host: " -t 180 doc_root

# Check if the virtual host configuration file already exists
if [ -f "/etc/apache2/sites-available/${domain}.conf" ]; then
  echo "Virtual host configuration file already exists. Exiting script."
  exit 1
fi

# Create the virtual host configuration file
echo "Creating virtual host configuration file..."

cat > "/etc/apache2/sites-available/${domain}.conf" <<EOL
<VirtualHost *:80>
  ServerName ${domain}
  ServerAdmin webmaster@localhost
  DocumentRoot ${doc_root}
  ErrorLog \${APACHE_LOG_DIR}/error.log
  CustomLog \${APACHE_LOG_DIR}/access.log combined
  Redirect permanent / https://${domain}/
</VirtualHost>
EOL

# Enable the virtual host and disable the default host
echo "Enabling virtual host and disabling default host..."
a2ensite "${domain}.conf"
a2dissite 000-default.conf

# Check if the SSL virtual host configuration file already exists
if [ -f "/etc/apache2/sites-available/${domain}-ssl.conf" ]; then
  echo "SSL virtual host configuration file already exists. Exiting script."
  exit 1
fi

# Create the SSL virtual host configuration file
echo "Creating SSL virtual host configuration file..."

cat > "/etc/apache2/sites-available/${domain}-ssl.conf" <<EOL
<IfModule mod_ssl.c>
  <VirtualHost *:443>
    ServerName ${domain}
    ServerAdmin webmaster@localhost
    DocumentRoot ${doc_root}
    ErrorLog \${APACHE_LOG_DIR}/error.log
    CustomLog \${APACHE_LOG_DIR}/access.log combined
    SSLEngine on
    SSLCertificateFile /etc/ssl/certs/${domain}.crt
    SSLCertificateKeyFile /etc/ssl/private/${domain}.key
    Header always set Strict-Transport-Security "max-age=63072000; includeSubdomains; preload"
  </VirtualHost>
</IfModule>
EOL

# Enable the SSL virtual host
echo "Enabling SSL virtual host..."
a2ensite "${domain}-ssl.conf"

# Reload Apache2 to apply the changes
echo "Reloading Apache2..."
systemctl reload apache2

echo "Virtual host setup complete."