#!/bin/bash
##############################################################################
##### infodisp.sh                 ############################################
##############################################################################
##### Main Script of infodisp     ############################################
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

if [ $sleep == 'usleep' ]
then
    sleep_multiplier=1000000
else
    sleep_multiplier=1
fi

#Hardcoded config
extmoddir="/etc/infodisp/modules-enabled"

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
	echo "--------------------"
	echo "$string_one"
        echo "$string_two"
	echo "--------------------"
    fi

    prev_string_one="$string_one"
    prev_string_two="$string_two"
}

function clock ()
{
    #Show clock and greeting
    time="$(date +%T) $(date +%x)"
    dispout "$greeting" "$time"
}

function uptime ()
{
    #Get uptime
    uptime=$(cat /proc/uptime |awk '{print $1}')
    ud=$(echo "$uptime/86400" | bc)
    uh2=$(echo "$uptime-86400*$ud" | bc)
    uh=$(echo "$uh2/3600" | bc)
    um2=$(echo "$uh2-3600*$uh" | bc)
    um=$(echo "$um2/60" | bc)
    us2=$(echo "$um2-60*$um" |bc)
    us=$(echo "$us2/1" | bc)
    uptime=$(printf  "%d days %02d:%02d:%02d\n" $ud $uh $um $us)
    if (( $(expr length $host) <= 12 )) ; then
	caption="$host uptime:"
    else
	caption="System uptime:"
    fi
    dispout "$caption" "$uptime"
}

function memcpu ()
{
    #Get cpu and memory usage
    cpus=$(grep -c ^processor /proc/cpuinfo)
    cpuload=$(top -bn 1 | awk 'NR>7{s+=$9} END {print s/4}')
    cpuload="CPU Load: "$(echo "scale=$accuracy; $cpuload/1" |bc)%
    memtotal=$(grep 'MemTotal' /proc/meminfo | awk '{print $2}')
    memfree=$(grep 'MemAvailable' /proc/meminfo | awk '{print $2}')
    doubleaccuracy=$(echo "$accuracy+2" |bc)
    memload=$(echo "scale=$doubleaccuracy; 100-$memfree/$memtotal*100" |bc)
    memload="Mem Load: "$(echo "scale=$accuracy; $memload/1" |bc)%
    dispout "$cpuload" "$memload"
    $sleep $(echo "0.2*$sleep_multiplier" |bc)
}

function netspeed ()
{
    #Get network interface status and Measure rx/tx speed
    iface=$1
    ifstate=`cat /sys/class/net/$iface/operstate`
    if [ $ifstate != "up" ]
    then
	dispout "Interface: $iface" "Interface is DOWN"
    else
        if [ -r /sys/class/net/$iface ]
	then
		rx1=$(ifconfig $iface |grep "bytes" |grep "RX" | awk '{print $5}')
		tx1=$(ifconfig $iface |grep "bytes" |grep "TX" | awk '{print $5}')
		$sleep $(echo "1*$sleep_multiplier" |bc)
		rx2=$(ifconfig $iface |grep "bytes" |grep "RX" | awk '{print $5}')
		tx2=$(ifconfig $iface |grep "bytes" |grep "TX" | awk '{print $5}')
		rxspeed=$(echo "($rx2-$rx1)*1*8/1024/1024" |bc)
		txspeed=$(echo "($tx2-$tx1)*1*8/1024/1024" |bc)
		speeds=$(printf "TX: %03d RX: %03d Mbps" $txspeed $rxspeed)
		dispout "Interface: $iface" "$speeds"
        else
		dispout "Interface: $iface" "Interface not found!"
        fi
    fi
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

#Checking external modules
extmodules=""
IFS=$'\n' extmodfiles=( $(find $extmoddir -name '*.module' -printf '%f\n') )
for extmodfile in "${extmodfiles[@]}"
do
    if [ -r "$extmoddir/$extmodfile" ]
    then
	enabled="0"
        source "$extmoddir/$extmodfile"
        if [ $enabled = "1" ]
        then
	    extmodules=$extmodules$extmodfile,
        fi
    fi
done

if [ -n "$extmodules" ]
then
    echo External modules found: $extmodules
else
    echo No external modules found!
fi

#Starting show in endless loop
while [ 0 ]
do
    if [ $modules = "all" ]
    then
	modules="clock,uptime,memcpu,netspeed"
    elif [ $modules = "external" ]
    then
	modules=""
    fi

    IFS=',' read -a modulelist <<< "$modules"
    for module in "${modulelist[@]}"
    do
	if [ $module = "netspeed" ]
	then
	    if [ $interfaces = "all" ]
	    then
		interfacelist=$(ls /sys/class/net |tr "\n" ",")
	    elif [ $interfaces = "running" ]
	    then
		interfacelist=$(ls /sys/class/net |tr "\n" ",")
	    else
		interfacelist=interfaces
	    fi

	    IFS=',' read -a interfacesarray <<< "$interfacelist"
	    for interface in "${interfacesarray[@]}"
	    do
		if [ $interface != 'lo' ]
		then
			if [ $interfaces = "running" ]
			then
			    ifstate=`cat /sys/class/net/$interface/operstate`
			    if [ $ifstate = "up" ]
			    then
				show $module $interface
			    fi
			else
			    show $module $interface
			fi
		fi
	    done
	else
	    show $module
	fi
    done

    IFS=',' read -a extmodulesarray <<< "$extmodules"
    for extmodule in "${extmodulesarray[@]}"
    do
	show $extmodule
    done

done
