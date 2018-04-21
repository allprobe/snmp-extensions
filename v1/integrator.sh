#!/bin/bash

noColor='\033[0m'
greenText='\033[1;32m'

APR_start_section="#####APR_START#####"
APR_end_section="#####APR_END#####"
getExtensionsLink="http://api.allprobe.lcl/v2/GetSnmpExtensions/"
apr_root=/etc/apr
apr_log_root=/var/log/apr/
system_scripts_local_dir=/etc/apr/cron/system/
user_scripts_local_dir=/etc/apr/cron/user/
user_extend_dir=/etc/apr/snmp/user/
system_extend_dir=/etc/apr/snmp/system/
system_buffer_dir=/etc/apr/buffer
cron_log="/var/log/apr/cron.log >/dev/null 2>&1"
snmp_daemon="snmpd"

function checkOS
{
  if [ -f /etc/issue ]; then
    fullOSInfo=$(cat /etc/issue)
    if [[ $fullOSInfo == *"Debian"* ]]; then
      snmp_daemon="snmpd"
      echo "Debian"
    fi
    if [[ $fullOSInfo == *"Ubuntu"* ]]; then
      snmp_daemon="snmpd"
      echo "Ubuntu"
    fi
    if [[ $fullOSInfo == *"CentOS"* ]]; then
      snmp_daemon="snmpd"
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
if [ ! -f /etc/apr/buffer.tmp ]; then
  return 0
else
    if [ ! -f /etc/apr/integrator.sh ]; then
      return 0
    else
      return 1
    fi

fi
}

function base64decode()
{
    if [[ -z `command -v base64`  ]];then
      if [[ -z `command -v python` ]];then
        if [[ -z `command -v perl` ]];then
          exit 1
        else
          perl -MMIME::Base64 -ne 'printf "%s\n",decode_base64($_)' <<< "$1"
        fi
      else
       echo "$1" | python -m base64 -d
      fi
    else
      echo "$1" | base64 -di
    fi
}

function isDifferent
{
  if [ "$1" == "$2" ]
    then
    return 1
  else
    return 0
  fi
}

function getNWord
{
  echo "$1" | cut -d " " -f $2
}

function installPre
{
echo -e "${greenText}Installing required software from OS repository..${noColor}"
case "$(checkOS)" in
  "Debian" | "Proxmox" | "Ubuntu")
if isFirstRun; then
  # TODO: check if needed
  # apt-get update
  apt-get -y install snmpd
  apt-get -y install mysql-client
  apt-get -y install which
fi
;;
"CentOS" | "Fedora")
yum -y install net-snmp mysql-client which
;;
*)
echo -e "${greenText}Error recognizing linux distribution!${noColor}\n"
;;
esac
}

function restartServices
{
echo -e "\n${greenText}Restarting Cron & snmpd daemon...${noColor}"

case "$(checkOS)" in
  "Debian" | "Proxmox" | "Ubuntu")
  snmp_daemon="snmpd"
  cron_daemon="cron"
  /etc/init.d/$snmp_daemon restart
  /etc/init.d/$cron_daemon restart
echo ""
;;
"CentOS" | "Fedora")
  snmp_daemon="snmpd"
  cron_daemon="crond"
  /etc/init.d/$snmp_daemon restart
  /etc/init.d/$cron_daemon restart
echo ""
;;
*)
echo -e "\n${greenText}Error recognizing linux distribution!${noColor}"
;;
esac
}

function checkSnmpDaemon()
{
printf "Checking SNMP daemon\n"

case "$(checkOS)" in
  "Debian" | "Proxmox" | "Ubuntu")
  snmp_daemon="snmpd"
;;
"CentOS" | "Fedora")
  snmp_daemon="snmpd"
;;
*)
echo -e ""
;;
esac

if (( $(ps -ef | grep -v grep | grep $snmp_daemon | wc -l ) < 1 )); then
printf "SNMP daemon is not running, restarting..\n"
/etc/init.d/$snmp_daemon restart
else
printf "SNMP daemon running, doing nothing\n\n"
fi


}
function createDirs
{
  echo -e "\n${greenText}Creating root directories${noColor}"
  mkdir -p "$apr_root"
  mkdir -p "$apr_log_root"
  mkdir -p "$system_scripts_local_dir"
  mkdir -p "$user_scripts_local_dir"
  mkdir -p "$user_extend_dir"
  mkdir -p "$system_extend_dir"
  mkdir -p "$system_buffer_dir"
}

function thisTokenId
{
  echo $(cat /etc/apr/token.id)
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

function addConfToAPRSection
{
sed -i "/$APR_end_section/i $1" $2
}

function fetchRemoteConfs
{
  downloaded_conf_output="$(wget --no-check-certificate -O- -q "$getExtensionsLink$(thisTokenId)")"

  echo $downloaded_conf_output
}

function addSnmpConfs
{
# echo "$1"
snmpConfs=$(echo "$1" | sed -n "/#snmpd#/,/#snmpd_end#/p" | sed '1d; $d')
# snmpConfs=$(echo "$1" | sed -n -e '/^snmpd$/,/^snmpd_end$/{ /^snmpd$/d; /^snmpd_end$/d; p; }')
echo -e "\nsetting configs at ${greenText}/etc/snmp/snmpd.conf${noColor}:\n$snmpConfs\n"

while read -r line; do
  if [ -z "$line" ]; then
    continue
  fi
  addConfToAPRSection "$line" /etc/snmp/snmpd.conf
done <<< "$snmpConfs"
addConfToAPRSection "\\\r" /etc/snmp/snmpd.conf
}

function addCrons
{
crons=$(echo "$1" | sed -n "/#cron#/,/#cron_end#/p" | sed '1d; $d')

if [[  -z  $crons  ]]; then
    crons="N/A"
    addConfToAPRSection " \\\n" /etc/crontab
else
   while read -r line; do
     if [ -z "$line" ]; then
       continue
     fi
     commandBinary=$(getNWord "$line" 6)
     commandBinaryFullPath=$(which "$commandBinary")

   newLine=$(echo "$line" | sed "s|$commandBinary|root $commandBinaryFullPath|1")
   addConfToAPRSection "$newLine" /etc/crontab
   done <<< "$crons"
   addConfToAPRSection " \\\n" /etc/crontab
fi

echo -e "setting configs at ${greenText}/etc/crontab${noColor} :\n$crons\n"


}

function downloadSnmpScripts
{
  snmpScripts=$(echo "$1" | sed -n "/#cdn-snmp#/,/#cdn-snmp_end#/p" | sed '1d; $d')
  echo -e "${greenText}Downloading SNMP scripts from CDN${noColor} :"

  if [[  -z  $snmpScripts  ]]; then
    echo "N/A"
  else
  while read -r line; do
    if [ -z "$line" ]; then
      continue
    fi
    echo "Downloading $line..."
    wget --no-check-certificate -q -P "$system_extend_dir" "$line"
  done <<< "$snmpScripts"
  chmod +x -R "$system_extend_dir"
  fi

}

function downloadCronScripts
{
  cronScripts=$(echo "$1" | sed -n "/#cdn-cron#/,/#cdn-cron_end#/p" | sed '1d; $d')
  echo -e "\n${greenText}Downloading CRON scripts from CDN${noColor} :"

  if [[  -z  $cronScripts  ]]; then
      echo "N/A"
  else
while read -r line; do
  if [ -z "$line" ]; then
    continue
  fi
  echo "Downloading $line..."
  wget --no-check-certificate -q -P "$system_scripts_local_dir" "$line"
done <<< "$cronScripts"
chmod +x -R "$system_scripts_local_dir"
  fi
}

function runCustomProcedures
{
  customProcedures=$(echo "$1" | sed -n "/#custom-procedure#/,/#custom-procedure_end#/p" | sed '1d; $d')
if [ -n "$customProcedures" ]; then

echo -e "${greenText}\nRunning custom procedures:${noColor}"

while read -r line; do
  if [ -z "$line" ]; then
    continue
  fi
  echo "Running \"$line\"..."
  eval $line
done <<< "$customProcedures"
fi
}

function echoNoInternetConnection
{
    echo -e "${greenText}Couldn't connect to API please check your internet connection and try again"
    echo -e "It's possible you need to export a proxy server to be able to have HTTP connection"
    echo -e "export https_proxy=https://..."
    echo -e "If you are using proxy.. don't forget to add it the following line at the beggining of /etc/crontab e.g.."
    echo -e "https_proxy=https://192.168.0.125:8888${noColor}"
    echo -e ""
}

function addIntegratorCron
{
  addConfToAPRSection "*/5 * * * * root $(which bash) /etc/apr/integrator.sh $2  | tee -a $cron_log >/dev/null 2>&1" /etc/crontab
}

function deleteAllFiles
{
  rm -f $system_scripts_local_dir*
  rm -f $system_extend_dir*
}

function commit
{
    # Remove APR sections.
    removeAPRSection /etc/crontab
    removeAPRSection /etc/snmp/snmpd.conf

    # Adding APR sections.
    addAPRSection /etc/crontab
    addAPRSection /etc/snmp/snmpd.conf

    # Comment out default binding
    sed -e '/agentAddress  udp:127.0.0.1:161/ s/^#*/#/' -i /etc/snmp/snmpd.conf

    addIntegratorCron
    addSnmpConfs "$1"
    addCrons "$1"
    deleteAllFiles

    downloadSnmpScripts "$1"
    downloadCronScripts "$1"

    runCustomProcedures "$1"

    restartServices
}

install(){
    echo -e "${greenText}-----AllProbe SNMP extensions integrator installation----- \n\nThis host ($(checkOS)) token is${noColor}: $(thisTokenId)"

    createDirs

    if isFirstRun ; then
      echo "Integrator not found, downloading & copying from /tmp into /etc/apr/ ..."
      if [ -f /tmp/integrator.sh ]; then
      cp /tmp/integrator.sh /etc/apr/
      fi
      chmod +x /etc/apr/integrator.sh
    else
      echo "Integrator found, doing nothing"
      cp /tmp/integrator.sh /etc/apr/
      chmod +x /etc/apr/integrator.sh
    fi

    confEncoded=$(fetchRemoteConfs)

# TODO: base64 output check rather then empty string
if [ -n "$confEncoded" ]; then

    allConfsDecoded=$(base64decode $confEncoded | grep -Ev "^$")

    echo "$confEncoded"

    if isFirstRun ; then
      installPre
      # TODO: check if installPre was succesful and if it is touch buffer.tmp
      touch /etc/apr/buffer.tmp
    fi

    case "$1" in
    normal) commit "$allConfsDecoded";;
    preventive)
        printf "\nRunning preventive mode... delaying commit changes\n" >&2
        touch "$system_buffer_dir/extensions.buffer"
    ;;
    secure)
        printf "\nRunning secure mode... writing changes to commit buffer\n" >&2
    ;;
    *)
          echo "\nNo argument passed choosing normal security mode\n" >&2
          commit "$allConfsDecoded"
    ;;
    esac

    echo "$allConfsDecoded" > "$system_buffer_dir/extensions.list"

else
    echoNoInternetConnection
fi


}

cron()
{
  if isFirstRun; then
    install
  else
    printf  "Running APR cron at: $(date +%Y-%m-%d-%H:%M:%S) \n"
    # fetch relevant confs
    confEncoded=$(fetchRemoteConfs)

# TODO: base64 output check rather then empty string
if [ -n "$confEncoded" ]; then

    allConfsDecoded=$(base64decode $confEncoded | grep -Ev "^$")

    if isDifferent "$allConfsDecoded" "$(cat "$system_buffer_dir/extensions.list")";then

        echo "different config found!"

        case "$1" in
        normal) commit "$allConfsDecoded";;
        preventive)
            printf "\nRunning preventive mode... delaying commit changes\n" >&2
            touch "$system_buffer_dir/extensions.buffer"
        ;;
        secure)
            printf "\nRunning secure mode... writing changes to commit buffer\n" >&2
        ;;
        *)
              printf "\nNo argument passed choosing normal security mode\n" >&2
              commit "$allConfsDecoded"
        ;;
        esac

        echo "$allConfsDecoded" > "$system_buffer_dir/extensions.list"

    else
        printf "Same config found. nothing changed.\n"

        if [ `stat --format=%Y "$system_buffer_dir/extensions.list"` -le $(( `date +%s` - 43200 )) ]; then
            allConfsDecoded=`cat $system_buffer_dir/extensions.list`
            commit "$allConfsDecoded"
            printf "\n"
        fi

        printf "\n"
    fi
else
    echoNoInternetConnection
fi
fi
    checkSnmpDaemon
}

purge()
{
  rm -fR /etc/apr
  rm -fR /var/log/apr

  removeAPRSection /etc/crontab
  removeAPRSection /etc/snmp/snmpd.conf

  restartServices
}


case "$1" in
install)
  case "$2" in
  normal) install normal;;
  preventive) install preventive;;
  secure) install secure;;
  *)
  printf "usage: $1 normal | preventive | secure\n" >&2
  printf "Choosing normal install\n\n" >&2
  install normal
  ;;
  esac
  ;;
purge)    purge ;;
reinstall) purge; install normal;;
cron)
  case "$2" in
  normal) cron normal;;
  preventive) cron preventive;;
  secure) cron secure;;
  *)
  printf "usage: $1 normal | preventive | secure\n" >&2
  printf "Choosing normal install\n\n" >&2
  cron
  ;;
  esac
;;
commit)
  allConfsDecoded=`cat $system_buffer_dir/extensions.list`
  commit "$allConfsDecoded"
  printf "\n\n"
  ;;
*) echo "usage: $0 install | purge | reinstall | cron" >&2
exit 1
;;
esac
