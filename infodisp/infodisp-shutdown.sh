#!/bin/bash
##############################################################################
##### infodisp.sh                 ############################################
##############################################################################
##### Shutdown Script of infodisp ############################################
##### version 1.1 2018/07/05      ############################################
##### System Status Daemon        ############################################
##### for Epson Mode Compatible   ############################################
##### Character Displays          ############################################
##############################################################################
##### (С) Vitaly Prokofiev, 2018  ############################################
##### infodisp.digitalvintage.ru  ############################################
##### Licensed under GNU GPL v3   ############################################
##############################################################################

#Load config
if [ -r /etc/infodisp/infodisp.conf ]
then
    source /etc/infodisp/infodisp.conf
else
    echo "Config read failed"
    exit
fi

#Init variables
prev_string_one=""
prev_string_two=""

#Get first part (before dot) of hostname
host=$(cat /proc/sys/kernel/hostname |awk -F"." '{print $1}')
for l in $host
do
    host=$(tr '[:lower:]' '[:upper:]' <<< ${l:0:1})${l:1}
done

function dispout ()
{

    #Sending two strings to the display
    string_one="$1"
    string_two="$2"
    screen_updated="no"

    #Making string length no more than 20 symbols to prevent artifacts and blinking
    string_one=${string_one:0:20}
    string_two=${string_two:0:20}
    #And not less than 20 to prevent the same
    #Define space symbol )))
    space=" "
    while (( $(expr length "$string_one") < 20 ))
    do
	string_one="$(echo "$string_one$space")"
    done
    while (( $(expr length "$string_two") < 20 ))
    do
	string_two="$(echo "$string_two$space")"
    done

    if [[ "$string_one" != "$prev_string_one" && "$string_two" != "$prev_string_two" ]]
    then
	#Disable the cursor
        echo -en '\x1f\x43\x00' > $device
	#Clear screen and move cursor to the first symbol of first string
        echo -en '\x0c\x0d' > $device
        echo "CLR"
    fi

    if [ "$string_one" != "$prev_string_one" ]
    then
        #Move cursor to the first symbol of first string
        echo -en '\x0b\x0d' > $device
	#Send first string (max 20char)
        echo -en "$string_one" > $device
        ###Print to screen for debug purposes
	screen_updated="yes"
    fi

    if [ "$string_two" != "$prev_string_two" ]
    then
        #Move cursor to the first symbol of second string
        echo -en '\x0a\x0d' > $device
        #Send second string (max 20char)
        echo -en "$string_two" > $device

        ###Print to screen for debug purposes
	screen_updated="yes"
    fi

    ###Print to screen for debug purposes
    if [ $screen_updated == "yes" ]
    then
OC	echo "--------------------"
	echo "$string_one"
        echo "$string_two"
	echo "--------------------"
    fi

    prev_string_one="$string_one"
    prev_string_two="$string_two"
}

function show ()
{
    #Continuous show with timeout
    starttime=$(date +%s)
    endtime=$(echo "$starttime+$showtime" |bc)
    while (( $(date +%s) <= $endtime ))
    do
	$1 $2 $3
	$sleep $(echo "0.075*$sleep_multiplier" |bc)
    done 
}

$sleep $(echo "0.5*$sleep_multiplier" |bc)
dispout "Display shutted down" "on $host"