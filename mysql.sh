#!/bin/bash

# -----------------------------------------------------------------------------------------------------------------
# Set the Root Password. This should include lower case letters, upper case letters, numbers and special characters.
# -----------------------------------------------------------------------------------------------------------------
DATABASE_PASSWORD=rootDBPass#12

# -----------------------------------------------------------------------------------------------------------------
# Remove Existing Installation. Comment Out these lines if not needed
# -----------------------------------------------------------------------------------------------------------------

echo 'Removing previous mysql server installation and MariaDB'
sudo systemctl stop mysqld.service && sudo yum remove -y mysql-community-server && sudo rm -rf /var/lib/mysql && sudo rm -rf /var/log/mysqld.log && sudo rm -rf /etc/my.cnf
sudo yum erase mariadb* -y
sudo yum erase mysql80-community-release.noarch -y

# -----------------------------------------------------------------------------------------------------------------
# Set Yum Repository and Install MySQL Community Server
# -----------------------------------------------------------------------------------------------------------------

echo 'Installing mysql server 8.0 Community Edition '
yum localinstall -y https://dev.mysql.com/get/mysql80-community-release-el8-4.noarch.rpm
yum install -y mysql-server-*

# -----------------------------------------------------------------------------------------------------------------
# Start MySQL Server and Grep Temporary Password
# -----------------------------------------------------------------------------------------------------------------
echo ' Starting mysql server for First Time'

sudo systemctl start mysqld.service 2>/dev/null
systemctl enable mysqld.service 2>/dev/null

tempRootPass="`sudo grep 'temporary.*root@localhost' /var/log/mysqld.log | tail -n 1 | sed 's/.*root@localhost: //'`"

# -----------------------------------------------------------------------------------------------------------------
# Set New Password for root user
# -----------------------------------------------------------------------------------------------------------------
echo 'Setting up new mysql server root password'

mysql -u "root" --password="$tempRootPass" --connect-expired-password -e "alter user root@localhost identified by '${DATABASE_PASSWORD}'; flush privileges;"

# -----------------------------------------------------------------------------------------------------------------
# Do the Basic Hardening
# -----------------------------------------------------------------------------------------------------------------


mysql -u root --password="$DATABASE_PASSWORD" -e "DELETE FROM mysql.user WHERE User=''; DROP DATABASE IF EXISTS test; DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%'; FLUSH PRIVILEGES;"
sudo systemctl status mysqld.service

# -----------------------------------------------------------------------------------------------------------------
# Perform a Sanity Check
# -----------------------------------------------------------------------------------------------------------------
echo "Sanity check: check if password login works for root."
mysql -u root --password="$DATABASE_PASSWORD" -e quit

# -----------------------------------------------------------------------------------------------------------------
#  Enable Firewall
# -----------------------------------------------------------------------------------------------------------------
echo "Enabling Firewall Service."
sudo firewall-cmd --permanent --add-service=mysql 2>/dev/null
sudo firewall-cmd --reload 2>/dev/null

# -----------------------------------------------------------------------------------------------------------------
# Final Output
# -----------------------------------------------------------------------------------------------------------------
echo "MySQL server installation completed, root password: $DATABASE_PASSWORD";
