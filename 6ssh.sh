#!/usr/bin/env bash

##################################################################################
#
#  Copyright (C) 2024 Craig Miller
#
#  See the file "LICENSE" for information on usage and redistribution
#  of this file, and for a DISCLAIMER OF ALL WARRANTIES.
#  Distributed under GPLv2 License
#
##################################################################################



#
#	6ssh: a shell program to ssh _from_ stable SLAAC Address
#
#	by Craig Miller
#
#	16 July 2024


# todo:
#	1) allow arbitrary ssh options (e.g. -o AddressFamily=inet6
#	BSD Supported - as of v0.9.2 		20 July 2024
# 	Added option -u for ULAs - v0.9.4	20 July 2024
#	2) fix interface seleciton with eth & wlan connected- cheating with sort for now 23 July 2024


#
# Source in IP command emulator (uses ifconfig, hense more portable)
#
OS=""
# check OS type
OS=$(uname -s)
if [ "$OS" == "Darwin" ] || [ "$OS" == "FreeBSD" ]; then
	# MacOS X/BSD compatibility
	source ip_em.sh
fi



function usage {
               echo "	$0 - ssh using Stable SLAAC Source Address "
	       echo "	e.g. $0 <host> "
	       echo "	-i <int> use this interface"
	       echo "	-u  use ULA address (default GUA)"
	       echo "	-X  use X forwarding"
	       echo "	"
	       echo " By Craig Miller - Version: $VERSION"
	       exit 1
           }

VERSION=1.0

# some variables

DEBUG=0

# ULA prefixes start with fd
PREFIX='fd'
# GUA prefixes start with 2
#
# Comment out next line, if only using ULAs
PREFIX='2'

IPV6_REG='[0-9a-f]{2,3}:([0-9a-f]+:){3,6}[:]?[0-9a-f]+'
INTERFACE=""

SSHOPTS=""

numopts=0
while getopts "?hdi:uXY" options; do
  case $options in
    i ) INTERFACE=$OPTARG
    	numopts=$(( numopts + 2));;
    d ) DEBUG=1
    	(( numopts++));;
    u ) PREFIX='fd'
    	(( numopts++));;
    X ) SSHOPTS="$SSHOPTS -X"
    	(( numopts++));;
    Y ) SSHOPTS="$SSHOPTS -Y"
    	(( numopts++));;
    h ) usage;;
    \? ) usage;;		# show usage with flag and no value
    * ) usage;;		# show usage with unknown flag
  esac
done
# remove the options as cli arguments
shift $numopts

#debug
#echo "$#	$1"

# get HOSTNAME of target
HOST=""
if [ -n "$1" ]; then
	HOST="$1"
else
	echo "Error: no host specified"
	usage
fi


function get_slaac_addr  {
	local local_intf="$1"
	# get IPv6 Stable SLAAC Address
	slaac_addr=""
	slaac_addr=$(ip addr show dev $local_intf | grep -E '(mngtmpaddr|noprefixroute|autoconf)' | grep -v 'temporary' | grep -o -E "$PREFIX$IPV6_REG" | tail -1)	
	#if (( DEBUG == 1 )); then echo "DEBUG: slaac_addr: $slaac_addr";fi
	echo -e "$slaac_addr"
}
 

slaac_addr=""
if [ -z "$INTERFACE" ]; then
	# set up a list of active interfaces (and ignore DORMANT in Linux)
	# fixme: select interface based on 'ip -6 route' and pick lowest metric
	INTF_LIST=$(ip link | grep -E '(LOWER_UP|UP,BROADCAST)' | grep -E -v '(LOOPBACK)' | cut -d ':' -f 2 | sort | tr '\n' ' ' )
	if (( DEBUG == 1 )); then echo "DEBUG:  INTF_LIST:$INTF_LIST";fi

	list_length=$(wc -w <<< "$INTF_LIST")
	if [ $list_length -gt 1 ]; then
		for intf in $INTF_LIST
		do
			tmp_addr=$(get_slaac_addr "$intf")
			if (( DEBUG == 1 )); then echo "DEBUG:  intf:$intf 	tmp_addr:$tmp_addr";fi
			if [ -n "$tmp_addr" ]; then
				slaac_addr="$tmp_addr"
				INTF="$intf"
				break
			fi
		done
		#error if no address found
		if [ -z "$slaac_addr" ]; then
			echo "Error: no IPv6 address found on interfaces"
			exit 1
		fi
	else
		slaac_addr=$(get_slaac_addr "$INTF_LIST")
		INTF="$INTF_LIST"
	fi
else
	# User specified interface
	INTF=$(ip link | grep -E '(LOWER_UP|UP,BROADCAST)' | cut -d ':' -f 2 | grep -o " $INTERFACE" )
	if [ -z "$INTF" ]; then
		echo "Error: Selected Interface: $INTERFACE is not found or DOWN"
		usage
	fi
	slaac_addr=$(get_slaac_addr "$INTF")
	if [ -z "$slaac_addr" ]; then
		echo "Error: No IPv6 address found on $INTERFACE"
		exit 1
	fi
fi


if (( DEBUG == 1 )); then echo "DEBUG:  INTF:$INTF	SLAAC ADDR=$slaac_addr";fi




# OK, lets ssh to host using Stable SLAAC Addr as source
ssh -b $slaac_addr $SSHOPTS "$HOST"

echo "6ssh: Pau"



