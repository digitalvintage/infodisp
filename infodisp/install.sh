#!/bin/bash
##############################################################################
##### install.sh                  ############################################
##############################################################################
##### infodisp Install Script     ############################################
##### version 1.1 2018/07/05      ############################################
##### System Status Daemon        ############################################
##### for Epson Mode Compatible   ############################################
##### Character Displays          ############################################
##############################################################################
##### (С) Vitaly Prokofiev, 2018  ############################################
##### infodisp.digitalvintage.ru  ############################################
##### Licensed under GNU GPL v3   ############################################
##############################################################################

ABSOLUTE_FILENAME=`readlink -e "$0"`
DIST_PATH=`dirname "$ABSOLUTE_FILENAME"`

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

mkdir /opt/infodisp
cp $DIST_PATH/infodisp.sh /opt/infodisp/
cp $DIST_PATH/infodisp-shutdown.sh /opt/infodisp/
chmod +x /opt/infodisp/infodisp.sh
chmod +x /opt/infodisp/infodisp-shutdown.sh
mkdir /opt/infodisp/modules
cp $DIST_PATH/modules/*.module /opt/infodisp/modules/
mkdir /etc/infodisp/
cp $DIST_PATH/infodisp.conf-example /etc/infodisp/infodisp.conf
mkdir /etc/infodisp/modules-enabled

#Creating symlinks for shipped external modules
extmodules=""
IFS=$'\n' extmodfiles=( $(find /opt/infodisp/modules -name '*.module' -printf '%f\n') )
for extmodfile in "${extmodfiles[@]}"
do
    ln -s /opt/infodisp/modules/$extmodfile /etc/infodisp/modules-enabled/$extmodfile
done

cp $DIST_PATH/infodispd.service $service_dir
systemctl daemon-reload
systemctl enable infodispd.service
echo "infodisp installation completed!"
echo "Now check config and run \"systemctl start infodispd\" to enable InfoDisp"
exit
