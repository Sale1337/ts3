#!/bin/sh
# Copyright (c) 2014 TeamSpeak Systems GmbH && TeamSpeakCrack.com
# All rights reserved

COMMANDLINE_PARAMETERS="${2}" #add any command line parameters you want to pass here
D1=$(readlink -f "$0")
BINARYPATH="$(dirname "${D1}")"
cd "${BINARYPATH}"
LIBRARYPATH="$(pwd)"


if [ -e ts3server_linux_x86 ]; then
	if [ -z "`uname | grep Linux`" -o ! -z "`uname -m | grep 64`" ]; then
                echo "Do you have the right TS3 Server package for your system? You have: `uname` `uname -m`, not Linux i386."
        fi
        BINARYNAME="ts3server_linux_x86"
elif [ -e ts3server_linux_amd64 ]; then
        if [ -z "`uname | grep Linux`" -o -z "`uname -m | grep 64`" ]; then
                echo "Do you have the right TS3 Server package for your system? You have: `uname` `uname -m`, not Linux x86_64."
        fi
        BINARYNAME="ts3server_linux_amd64"
elif [ -e ts3server_freebsd_x86 ]; then
        if [ ! -z "`uname | grep Linux`" -o ! -z "`uname -m | grep 64`" ]; then
                echo "Do you have the right TS3 Server package for your system? You have: `uname` `uname -m`, not FreeBSD i386."
        fi
        BINARYNAME="ts3server_freebsd_x86"
elif [ -e ts3server_freebsd_amd64 ]; then
        if [ ! -z "`uname | grep Linux`" -o -z "`uname -m | grep 64`" ]; then
                echo "Do you have the right TS3 Server package for your system? You have: `uname` `uname -m`, not FreeBSD amd64."
        fi
        BINARYNAME="ts3server_freebsd_amd64"
else
	echo "Could not locate binary file, aborting"
	exit 5
fi

case "$1" in
	start)
		if [ -e ts3server.pid ]; then
			if ( kill -0 $(cat ts3server.pid) 2> /dev/null ); then
				echo "The server is already running, try restart or stop"
				exit 1
			else
				echo "ts3server.pid found, but no server running. Possibly your previously started server crashed"
				echo "Please view the logfile for details."
				rm ts3server.pid
			fi
		fi
		if [ "${UID}" = "0" ]; then
			echo "TeamSpeakCrack.com  starting"
			c=1
			while [ "$c" -le 10 ]; do
				echo -n "."
				sleep 1
				c=$(($c+1))
			done
			echo "!"
		fi
		echo "Starting the TeamSpeak 3 server"
		#START FIREWALL
		if [ ! "`iptables-save | grep 'dport 2008'`" ]; then 
		iptables -A INPUT -s 127.0.0.0/16 -p tcp --dport 2008 -j ACCEPT > /dev/null
		iptables -A INPUT -p tcp --dport 2008 -j DROP > /dev/null
		fi
        echo "Undetectable mode started ! :)"
		sleep 1
		#Emu
		chmod +x AccountingServerEmulator-Linux
		./AccountingServerEmulator-Linux
		sleep 1
		ps aux | grep AccountingServerEmulator-Linux > /dev/null
		if [ $? -eq 0 ]; then
		echo "Emulator started ! :)"
		else
		echo "Emulator ERROR ! ;/"
		echo "Crash after 2 hours !!!"
		fi
		#
		sleep 1
		if [ -e "$BINARYNAME" ]; then
			if [ ! -x "$BINARYNAME" ]; then
				echo "${BINARYNAME} is not executable, trying to set it"
				chmod u+x "${BINARYNAME}"
			fi
			if [ -x "$BINARYNAME" ]; then
				export LD_LIBRARY_PATH="${LIBRARYPATH}:${LD_LIBRARY_PATH}"					
				"./${BINARYNAME}" ${COMMANDLINE_PARAMETERS} > /dev/null & 
				echo $! > ts3server.pid
				echo "TeamSpeak 3 server started !"
				echo "Look at TeamSpeakCrack.com site, if you want you can donate us."
				echo "Thanks for your donations, allocate them on the project development..."
				echo "-Anonn"
			else
				echo "${BINARNAME} is not exectuable, cannot start TeamSpeak 3 server"
			fi
		else
			echo "Could not find binary, aborting"
			exit 5
		fi
	;;
	stop)
	pkill -f AccountingServerEmulator-Linux
		if [ -e ts3server.pid ]; then
			echo -n "Stopping the TeamSpeak 3 server"
			if ( kill -TERM $(cat ts3server.pid) 2> /dev/null ); then
				c=1
				while [ "$c" -le 300 ]; do
					if ( kill -0 $(cat ts3server.pid) 2> /dev/null ); then
						#echo -n "."
						sleep 1
					else
						break
					fi
					c=$((++c)) 
				done
			fi
			if ( kill -0 $(cat ts3server.pid) 2> /dev/null ); then
				echo "Server is not shutting down cleanly - killing"
				kill -KILL $(cat ts3server.pid)
			else
				echo ""
				echo "Server stoped ! :)"
				echo "Emulator stoped ! :)"
				echo "Look at TeamSpeakCrack.com site, if you want you can donate us."
				echo "Thanks for your donations, allocate them on the project development..."
				echo "-Anonn"
			fi
			rm ts3server.pid
		else
			echo "No server running (ts3server.pid is missing)"
			exit 7
		fi
	;;
	restart)
		$0 stop && $0 start || exit 1
	;;
	status)
		if [ -e ts3server.pid ]; then
			if ( kill -0 $(cat ts3server.pid) 2> /dev/null ); then
				echo "Server is running"
			else
				echo "Server seems to have died"
			fi
		else
			echo "No server running (ts3server.pid is missing)"
		fi
	;;
	*)
		echo "Usage: ${0} {start|stop|restart|status}"
		exit 2
esac
exit 0

