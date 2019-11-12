#!/bin/bash
##############################################################################
##### remove.sh                   ############################################
##############################################################################
##### infodisp Uninstall Script   ############################################
##### version 1.1 2018/07/05      ############################################
##### System Status Daemon        ############################################
##### for Epson Mode Compatible   ############################################
##### Character Displays          ############################################
##############################################################################
##### (С) Vitaly Prokofiev, 2018  ############################################
##### infodisp.digitalvintage.ru  ############################################
##### Licensed under GNU GPL v3   ############################################
##############################################################################

if [ -r /usr/lib/systemd/system/network.target ]
then
    service_dir="/usr/lib/systemd/system/"
elif [ -r /lib/systemd/system/network.target ]
then
    service_dir="/lib/systemd/system/"
else
    echo "Error finding services directory"
    exit
fi

systemctl stop infodispd.service
systemctl disable infodispd.service
rm $service_dir/infodispd.service -f
rm /etc/infodisp/modules-enabled -rf
rm /etc/infodisp/infodisp.conf -f
rm /etc/infodisp/ -rf
rm /opt/infodisp/modules -rf
rm /opt/infodisp -rf
systemctl daemon-reload

echo "infodisp removing completed!"
exit
