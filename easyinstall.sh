#!/bin/bash

### START EDIT SETTINGS

# Path where to install SELKS files
PATH_SELKS=$HOME/SELKS

# SETUP CONFIG SCRIPT
INSTALL_DUMMY_INTERFACE=false
INSTALL_MIKROSNORT_SERVICE=true

### END EDIT SETTINGS

echo "--- Install required package ---"

apt-get install ca-certificates curl wget unzip  gnupg  lsb-release build-essential python3-pip git htop libpcap-dev -y
pip3 install pyinotify ujson requests librouteros

PATH_GIT_MIKROSNORT=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
sed -i '/SELKS_CONTAINER_DATA_SURICATA_LOG=/c\SELKS_CONTAINER_DATA_SURICATA_LOG="'$PATH_SELKS'/docker/containers-data/suricata/logs/"' "$PATH_GIT_MIKROSNORT/mikrosnort.py"


if $INSTALL_DUMMY_INTERFACE
then
    echo "--- Install packet sniffer interface ---"
    wget -P /opt https://github.com/thefloweringash/tzsp2pcap/archive/master.zip
    cd /opt
    unzip /opt/master.zip
    cd /opt/tzsp2pcap-master/
    make
    make install

    wget -P /opt https://github.com/appneta/tcpreplay/releases/download/v4.4.2/tcpreplay-4.4.2.tar.gz
    cd /opt
    tar -xf /opt/tcpreplay-4.4.3.tar.gz -C /opt
    cd /opt/tcpreplay-4.4.3/
    ./configure
    make
    make install

    echo "--- Creating interface ---"
    cp $PATH_GIT_MIKROSNORT/tzsp.netdev /etc/systemd/network/
    cp $PATH_GIT_MIKROSNORT/tzsp.network /etc/systemd/network/
    systemctl enable systemd-networkd
    systemctl restart systemd-networkd

    echo "--- Create service for interface dummy ---"
    cp $PATH_GIT_MIKROSNORT/TZSPreplay@.service /etc/systemd/system/
    systemctl enable --now TZSPreplay@tzsp0.service
fi

if $INSTALL_MIKROSNORT_SERVICE
then
    echo "--- Installing mikrosnort and his service ---"
    cp $PATH_GIT_MIKROSNORT/mikrosnort.py /usr/local/bin/
    chmod +x /usr/local/bin/mikrosnort.py
    mkdir -p /var/lib/mikrosnort
    touch /var/lib/mikrosnort/savelists.json
    touch /var/lib/mikrosnort/uptime.bookmark
    touch /var/lib/mikrosnort/ignore.conf
    cp $PATH_GIT_MIKROSNORT/mikrosnort.service /etc/systemd/system/
    systemctl enable --now mikrosnort.service
fi



echo "--- INSTALL COMPLETED ---"
echo "--- "
echo "--- "
echo "--- Edit '/usr/local/bin/mikrosnort.py' with your info and then reload service with 'systemctl restart mikrosnort.service'"
echo "--- Remember to configure Mikrotik"
echo "--- "
