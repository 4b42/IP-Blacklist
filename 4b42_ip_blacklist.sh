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
# For more Infomation visit www.4b42.com.                               #
# This notice must be untouched at all times.                           #
#-----------------------------------------------------------------------#

#-----------------------------------------------------------------------#
# 2014-03-26	Kevin Buehl		created
#-----------------------------------------------------------------------#
# you can find your api key in your profile at https://www.4b42.com
APIKEY=""
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
# files
IPS=$(cat /etc/fail2ban/ip.blacklist)
wget -q --header="X-4B42-KEY:${APIKEY}" --post-data="ips=$IPS" --post-file=ip -O /etc/fail2ban/ip.blacklist https://api.4b42.com/tools/blacklist/ip