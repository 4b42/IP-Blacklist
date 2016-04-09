#!/bin/bash
#-----------------------------------------------------------------------#
# Copyright 2006-2015 by Kevin Buehl                                    #
#-----------------------------------------------------------------------#
#  __          __    _____________    __          __    ______________  #
# |  |  2006  |  |  |   _______   \  |  |        |  |  |___________   | #
# |  |  2015  |  |  |  |       \  |  |  |        |  |              |  | #
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
# 2014-03-26	Kevin Buehl		created
# 2015-01-13	Kevin Buehl		fix update only on status code 200
# 2015-12-07	Kevin Buehl		add new url for ip blacklist
# 2015-12-10	Kevin Buehl		check if apikey file exist
# 2016-04-09	Kevin Buehl		add --no-check-certificate for wget
#-----------------------------------------------------------------------#
# check if apikey file exist
if ! [ -f "/opt/4b42/api.key" ]; then
   echo "Please use our install script." 1>&2
   exit 1
else
   APIKEY=$(cat /opt/4b42/api.key)
fi
# check if script run as root
if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi
# check if fail2ban installed
if [ ! -d "/etc/fail2ban/" ]; then
   echo "please install fail2ban"
   exit 1
elif [ ! -e "/etc/fail2ban/ip.blacklist" ]; then
   touch /etc/fail2ban/ip.blacklist
fi
# check if apikey not empty
if [ -z "$APIKEY" ]; then
   echo "Please enter your APIKEY in file /opt/4b42/api.key"
fi
# files
IPS=$(cat /etc/fail2ban/ip.blacklist)
status=`wget --header="4B42-KEY:${APIKEY}" --post-data="ips=$IPS" -O /tmp/ip.blacklist https://api.4b42.com/tools/security/blacklist.text --no-check-certificate 2>&1 |egrep "HTTP"|awk {'print $6'}`
if [ "$status" == 200 ]; then
   rm -f /etc/fail2ban/ip.blacklist
   mv /tmp/ip.blacklist /etc/fail2ban/ip.blacklist
elif [ -e "/tmp/ip.blacklist" ]; then
   echo $(cat /tmp/ip.blacklist);
fi
# reload fail2ban service
service fail2ban reload