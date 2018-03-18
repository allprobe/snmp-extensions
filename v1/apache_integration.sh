#!/bin/bash

APR_start_section="#####APR_START#####"
APR_end_section="#####APR_END#####"

function checkOS
{
  if [ -f /etc/issue ]; then
    fullOSInfo=$(cat /etc/issue)
    if [[ $fullOSInfo == *"Debian"* ]]; then
      echo "Debian"
    fi
    if [[ $fullOSInfo == *"Ubuntu"* ]]; then
      echo "Ubuntu"
    fi
    if [[ $fullOSInfo == *"CentOS"* ]]; then
      echo "CentOS"
    fi
    if [[ $fullOSInfo == *"Fedora"* ]]; then
      echo "Fedora"
    fi
    if [[ $fullOSInfo == *"Proxmox"* ]]; then
      echo "Proxmox"
    fi
  else
    fullOSInfo=$(cat /etc/*-release)
    if [[ $fullOSInfo == *"Debian"* ]]; then
      echo "Debian"
    fi
    if [[ $fullOSInfo == *"Ubuntu"* ]]; then
      echo "Ubuntu"
    fi
    if [[ $fullOSInfo == *"CentOS"* ]]; then
      echo "CentOS"
    fi
    if [[ $fullOSInfo == *"Fedora"* ]]; then
      echo "Fedora"
    fi
    if [[ $fullOSInfo == *"Proxmox"* ]]; then
      echo "Proxmox"
    fi
  fi
}

function isFirstRun
{
#        echo "Checking if integrator on his first run..."
if [ ! -f /etc/apr/integrator.sh ]; then
  return 0
else
  return 1
fi
}

function installPre
{
# echo "installing required software..."
case "$(checkOS)" in
  "Debian" | "Proxmox" | "Ubuntu")
if isFirstRun; then
  apt-get update
  apt-get -y install links
fi
;;
"CentOS" | "Fedora")
yum install links
;;
*)
echo "Error recognizing linux distribution!"
;;
esac
}

function restartServices
{
#	echo "installing required software..."
case "$(checkOS)" in
	"Debian" | "Proxmox" |"Ubuntu")
/etc/init.d/apache2 reload
;;
"CentOS" | "Fedora")
service httpd reload
;;
*)
echo "Error recognizing linux distribution!"
;;
esac
}

function addAPRSection
{
	extensionsSection=`grep $APR_start_section $1`
	if [ -z "$extensionsSection" ]; then
		echo $APR_start_section >> $1
		printf "\n" >> $1
		echo $APR_end_section >> $1
	fi
}

function removeAPRSection
{
	echo "$(sed "/$APR_start_section/,/$APR_end_section/d" "$1")" > $1
}

function isAPRSection
{
	extensionsSection=`grep $APR_start_section $1`
	if [ -z "$extensionsSection" ]; then
		echo "false"
	else
		echo "true"
	fi
}

# 1st param=config to be added, 2nd param=config file to add to.
function addConfToAPRSection
{
    sed -i "/$APR_end_section/i $1" $2
}

isApacheStatusConfigEnable()
{
	case "$(checkOS)" in
		"Debian" | "Proxmox" | "Ubuntu")

# file base search

#if [[ $(grep -rnw '/etc/apache2/mods-enabled/' -e "LoadModule status_module") ]]; then
#	echo "enabled"
#else
#	echo "not enabled"
#fi

# apache2ctl
if [[ $(apache2ctl -M | grep status_module) ]]; then
	echo "enabled"
else
	echo "not enabled"
fi

;;
"CentOS" | "Fedora")
echo "/etc/httpd/conf/httpd.conf";
;;
*)
echo "Error recognizing linux distribution!"
;;
esac

}

getApacheConfig()
{
	case "$(checkOS)" in
		"Debian" | "Proxmox" | "Ubuntu")

# file base search

#if [[ $(grep -rnw '/etc/apache2/mods-enabled/' -e "LoadModule status_module") ]]; then
#	echo "enabled"
#else
#	echo "not enabled"
#fi

# apache2ctl
echo "/etc/apache2/apache2.conf"

;;
"CentOS" | "Fedora")
echo "/etc/httpd/conf/httpd.conf";
;;
*)
echo "Error recognizing linux distribution!"
;;
esac

}

getApacheUptimeSecs()
{

uptimeSecs=0;
uptimeLine=$(cat /etc/apr/buffer/apache_status | grep 'Server uptime:')
#echo $uptimeLine


for i in `seq 1 10`;
do

	i_word=$(echo "$uptimeLine" | cut -d " " -f $i)
	#echo "$i_word"
	#before_i_word=$(echo "$(($i-1))")



	case "$i_word" in
		minutes) 

uptime_minutes=$(echo "$uptimeLine" | cut -d " " -f "$before_i_word")
uptimeSecs="$(($uptimeSecs+$(($uptime_minutes*60))))"
echo "minutes added"
;;
seconds) 
uptime_seconds=$(echo "$uptimeLine" | cut -d " " -f "$before_i_word")
uptimeSecs="$(($uptimeSecs+$uptime_seconds))"
echo "seconds added"
;;
hours) 
uptime_hours=$(echo "$uptimeLine" | cut -d " " -f "$before_i_word")
uptimeSecs="$(($uptimeSecs+$(($uptime_hours*3600))))"
echo "hours added"
;;
day) 
uptime_days=$(echo "$uptimeLine" | cut -d " " -f "$before_i_word")
uptimeSecs="$(($uptimeSecs+$(($uptime_days*86400))))"
echo "days added"
;;
*) echo "nothing added"
;;
esac

done
echo $uptimeSecs
#echo "$uptimeLine" | grep -o -P '.{0,3}string.{0,4}'

}



# 1st parameter = config to append to.
addStatusLocation()
{
    addConfToAPRSection "ExtendedStatus on" $1
    addConfToAPRSection "\\\r" $1
	addConfToAPRSection "<Location \"/apache-status-apr\">" $1
	addConfToAPRSection "SetHandler server-status" $1
	addConfToAPRSection "Order Deny,allow" $1
	addConfToAPRSection "Deny from all" $1
	addConfToAPRSection "Allow from 127.0.0.0/255.0.0.0" $1
	addConfToAPRSection "</Location>" $1
	addConfToAPRSection "\\\r" $1
}

status()
{
	getApacheUptimeSecs
	if [ "string1" == "string2" ]; then
		echo "true"
	else
		echo "false"
	fi

	if [ "$(isApacheStatusConfigEnable)" == "enabled" ]; then
		echo "module status enabled in config file."
		if [[ $(isAPRSection $(getApacheConfig)) = true ]]; then
			echo "apache allprobe integration is enabled."
		else
			echo "apache allprobe integration is disabled."
		fi
	else
		echo "module status doesn't enabled in config file."
		if [[ $(isAPRSection $(getApacheConfig)) = true ]]; then
			echo "apache allprobe integration is enabled."
		else
			echo "apache allprobe integration is disabled."
		fi
	fi
}

add()
{
	installPre
	removeAPRSection "$(getApacheConfig)"
	if [ "$(isApacheStatusConfigEnable)" == "enabled" ]; then
		echo "module status enabled in config file.";
	else
		echo "module status doesn't enabled in config file.";
		a2enmod status
	fi
        #if [[ "$(isAPRSection $(getApacheConfig))" = false ]]; then
	#	#add apache location with server status
	#	addAPRSection "$(getApacheConfig)"
	#	echo "apr section doesn't exists, adding apache status configuration to $(getApacheConfig)"
	#else
	#echo "apr section exists, adding apache status configuration to $(getApacheConfig)"
	#fi
	addAPRSection "$(getApacheConfig)"
	addStatusLocation "$(getApacheConfig)"
	restartServices
}

remove()
{
	echo "removing status location from apache config...";
	removeAPRSection "$(getApacheConfig)"
}

case "$1" in 
	add)   add ;;
remove)    remove ;;
status)    status ;;
*) echo "usage: $0 add|remove|status" >&2
exit 1
;;
esac