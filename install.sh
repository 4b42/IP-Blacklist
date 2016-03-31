#!/bin/bash
#-----------------------------------------------------------------------#
# Copyright 2006-2016 by Kevin Buehl                                    #
#-----------------------------------------------------------------------#
#  __          __    _____________    __          __    ______________  #
# |  |  2006  |  |  |   _______   \  |  |        |  |  |___________   | #
# |  |  2016  |  |  |  |       \  |  |  |        |  |              |  | #
# |  |___ ____|  |  |  |_______/  /  |  |___ ____|  |   ___________|  | #
# |______ ____   |  |   _______  |   |______ ____   |  |   ___________| #
#  by         |  |  |  |       \  \  Content     |  |  |  |             #
#    Kevin    |  |  |  |_______/  |   Management |  |  |  |___________  #
#      Buehl  |__|  |_____________/     System   |__|  |______________| #
#                                                                       #
# No part of this website or any of its contents may be reproduced,     #
# copied, modified or adapted, without the prior written consent of     #
# the author, unless otherwise indicated for stand-alone materials.     #
# For more Information visit www.4b42.com.                              #
# This notice must be untouched at all times.                           #
#-----------------------------------------------------------------------#

#-----------------------------------------------------------------------#
# 2016-03-15	Maik Ballichar	created
# 2016-03-31	Kevin Buehl	optimization and clean up
#-----------------------------------------------------------------------#
#check if debian is installed
if ! [ -f "/etc/debian_version" ]; then
   echo "Only Debian/Ubuntu are supported. Please be patient or install it manually."
   exit 1
fi

# check if script run as root
if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

# first of all we take a look for system update
apt-get -qq update && apt-get -qq upgrade

# check if cron is installed
PKG_OK=$(dpkg-query -W --showformat='${Status}\n' cron|grep "install ok installed")
echo Checking for cron: $PKG_OK
if [ "" == "$PKG_OK" ]; then
   echo "No cron installed. Installing cron."
   apt-get -qq install cron
fi

# check if fail2ban is installed
PKG_OK=$(dpkg-query -W --showformat='${Status}\n' fail2ban|grep "install ok installed")
echo Checking for Fail2Ban: $PKG_OK
if [ "" == "$PKG_OK" ]; then
   echo "No Fail2Ban installed. Installing Fail2Ban."
   apt-get -qq install fail2ban
fi

# create ip.blacklist 
if [ -f "/etc/fail2ban/ip.blacklist" ]; then
   echo "ip.blacklist already exist."
else
   touch /etc/fail2ban/ip.blacklist
   echo "Blacklist file created."
fi

# get modified iptables-multiport.conf
wget -O /tmp/iptables-multiport.conf https://raw.githubusercontent.com/4b42/IP-Blacklist/master/fail2ban/action.d/iptables-multiport.conf --no-check-certificate
if [ -f "/tmp/iptables-multiport.conf" ]; then
   diff /etc/fail2ban/action.d/iptables-multiport.conf /tmp/iptables-multiport.conf > /dev/null 2>&1
   if [ "$?" -eq 0 ]; then
      rm -f /tmp/iptables-multiport.conf
      echo "No modification on iptables-multiport.conf needed."
   else
      if [ -f "/etc/fail2ban/action.d/iptables-multiport.conf" ]; then
         mv /etc/fail2ban/action.d/iptables-multiport.conf /etc/fail2ban/action.d/iptables-multiport.conf.bak
         mv /tmp/iptables-multiport.conf /etc/fail2ban/action.d/iptables-multiport.conf
         echo "Got modified iptables-multiport.conf"
      else
         mv /tmp/iptables-multiport.conf /etc/fail2ban/action.d/iptables-multiport.conf
         echo "iptables-multiport.conf installed."
      fi
   fi
else
   echo "Failure getting modified iptables-multiport.conf. Please contact 4b42 support."
   exit
fi

# get 4b42_ip_blacklist.sh
if ! [ -d "/opt/4b42/security" ]; then
   mkdir -p /opt/4b42/security/
fi
wget -O /tmp/4b42_ip_blacklist.sh https://raw.githubusercontent.com/4b42/IP-Blacklist/master/4b42_ip_blacklist.sh --no-check-certificate
if [ -f "/tmp/4b42_ip_blacklist.sh" ]; then
   diff /opt/4b42/security/4b42_ip_blacklist.sh /tmp/4b42_ip_blacklist.sh > /dev/null 2>&1
   if [ "$?" -eq 0 ]; then
      rm -f /tmp/4b42_ip_blacklist.sh
      echo "No new version of 4b42_ip_blacklist.sh available."
   else
      if [ -f "/opt/4b42/security/4b42_ip_blacklist.sh" ]; then
         mv /opt/4b42/security/4b42_ip_blacklist.sh /opt/4b42/security/4b42_ip_blacklist.sh.bak
         mv /tmp/4b42_ip_blacklist.sh /opt/4b42/security/4b42_ip_blacklist.sh
         chmod +x /opt/4b42/security/4b42_ip_blacklist.sh
         echo "New Version was downloaded. Old one are backed up."
      else
         read -p "Please insert your API-Key. You can find it in your profile at https://www.4b42.com: " APIKEY
         echo $APIKEY > /opt/4b42/api.key
         chmod 700 /opt/4b42/api.key
         mv /tmp/4b42_ip_blacklist.sh /opt/4b42/security/4b42_ip_blacklist.sh
         chmod +x /opt/4b42/security/4b42_ip_blacklist.sh
         echo "4b42_ip_blacklist.sh downloaded."
      fi
   fi
else
   echo "Failure getting 4b42_ip_blacklist.sh. Please contact 4b42 support."
   exit
fi

# create crontab
if [ -f "/opt/4b42/security/blacklist_cron" ]; then
   echo "Crontab already exist. Let's do a fail2ban reload."
   /opt/4b42/security/4b42_ip_blacklist.sh
else
   crontab -l > /opt/4b42/security/blacklist_cron
   echo "0 0 * * * /opt/4b42/security/4b42_ip_blacklist.sh" >> /opt/4b42/security/blacklist_cron
   crontab /opt/4b42/security/blacklist_cron
   echo "Crontab created to run every day 12AM. Please use 'crontab -e' to modify."
   /opt/4b42/security/4b42_ip_blacklist.sh
fi
exit