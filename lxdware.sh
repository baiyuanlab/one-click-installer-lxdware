#! /bin/bash
# Check OS support
distr=`echo $(lsb_release -i | cut -d':' -f 2)`
osver=`echo $(lsb_release -c | cut -d':' -f 2)`

if ! [[ $distr == "Ubuntu" && $osver =~ ^(bionic|focal)$ ]]; then
	echo "$(tput setaf 1)"
	echo "****************************************************************************"
	echo "**** This OS is not supported by LXD Dashboard and could not work properly *"
	echo "****************************************************************************"
	echo "$(tput sgr0)"
	read -p "Press [Enter] key to Continue or [Ctrl+C] to Cancel..."
fi

# Check LXC command exists.
clear
a=/snap/bin/lxc
if [ -f "$a" ]; then
    echo "$a exists."
    read -p "Press [Enter] key to start install LXD Dashboard"

# Delete container
lxc delete lxd-dashboard --force

read -t 5 -p "I am going to wait for 5 seconds ..."
clear
echo "****************************************************************************"
echo "********************** Delete container done *******************************"
echo "****************************************************************************"

# Create container
lxc launch ubuntu:20.04 lxd-dashboard
sleep 5

# Apt update and apt install nginx php-fpm php-curl sqlite3 php-sqlite3
lxc exec lxd-dashboard -- sh -c "apt update -y && apt dist-upgrade -y && apt autoremove -y && apt install nginx php-fpm php-curl sqlite3 php-sqlite3 -y"

clear
echo "****************************************************************************"
echo "********************** LXD Dashboard OS Update done **************************"
echo "****************************************************************************"

# Download and install lxd-dashboard
lxc exec lxd-dashboard -- sh -c "wget https://github.com/lxdware/lxd-dashboard/archive/v3.4.0.tar.gz && tar -xzf v3.4.0.tar.gz"

# Copy lxd-dashboard default config to /etc/nginx/sites-available and copy lxd-dashboard-3.4.0/lxd-dashboard to /var/www/html/
lxc exec lxd-dashboard -- sh -c "cp -a lxd-dashboard-3.4.0/default /etc/nginx/sites-available/ && cp -a lxd-dashboard-3.4.0/lxd-dashboard /var/www/html/"

# Create dir /var/lxdware/data/sqlite and /var/lxdware/data/lxd and /var/lxdware/backups
lxc exec lxd-dashboard -- sh -c "mkdir -p /var/lxdware/data/sqlite && mkdir -p /var/lxdware/data/lxd && mkdir -p /var/lxdware/backups"

# Chown dir owner
lxc exec lxd-dashboard -- sh -c "chown -R www-data:www-data /var/lxdware/ && chown -R www-data:www-data /var/www/html"

# Restart nginx
lxc exec lxd-dashboard -- sh -c "systemctl restart nginx"

# Delete Profile
lxc profile delete lxd-dashboard-proxy-port-80

# Create Profile
lxc profile create lxd-dashboard-proxy-port-80

# Create proxy
lxc profile device add lxd-dashboard-proxy-port-80 hostport80 proxy connect="tcp:127.0.0.1:80" listen="tcp:0.0.0.0:80"

# Add container to profile
lxc profile add lxd-dashboard lxd-dashboard-proxy-port-80

# Show info
b=$(dig +short myip.opendns.com @resolver1.opendns.com)
c="http://"
d=($c$b)
clear
echo "****************************************************************************"
echo "********************** LXD Dashboard Install done **************************"
echo "****************************************************************************"
echo "$d"

else
    echo "$a does not exist."
    echo "Manage remote LXD servers with this open source LXD dashboard for instructions on using the dashboard, visit https://lxdware.com"
    read -p "Press [Enter] key to Continue or [Ctrl+C] to Cancel... install LXD Dashboard"
fi
