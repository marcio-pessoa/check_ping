#!/bin/bash
#!/usr/local/bin/bash
#
# check_ping.sh
#
# Description: Program file
#

# Get program path
PROGPATH=`echo $0 | sed -e 's,[\\/][^\\/][^\\/]*$,,'` 

# Program information
PROGNAME=check_ping.sh
PVERSION="0.003b-dev"
DESCRIPT="$PROGNAME is used to check connection statistics for a remote host"
PRPROMPT=$PROGNAME

# Return states
OK=0
WARNING=1
CRITICAL=2
UNKNOWN=3

# Internal variables
TRUE=1
FALSE=0
ERROR=1
DEBUG=$FALSE
VERBOSE=$FALSE
SO=`uname`

# PING variables
PING_HOST=""
PING_SOURCE=""
PING_PACKETS=5
PING_TIMEOUT=10

# Check variables
LEVEL_WARNING=100,10%
LEVEL_CRITICAL=500,40%
PING_PL=100 # Default value to package lost
PING_AT=0 # Default value to averange time

help () {
  echo -e "$DESCRIPT.
  
Usage: $PROGNAME -f [FILE] -o [DIRECTORY]

Options:
  -h, --help                Print detailed help screen
  -V, --version             Print version information
  -H, --hostname=HOST       host to ping
  -S, --source=IP           Source IP address
  -w, --warning=THRESHOLD   warning threshold pair (default: 100,10%)
  -c, --critical=THRESHOLD  critical threshold pair (default: 500,40%)
  -p, --packets=INTEGER     number of ICMP ECHO packets to send (default: 5)
  -t, --timeout=INTEGER     Seconds before connection times out (default: 10)

Examples:
  $PROGNAME -H example.com
  $PROGNAME -S 192.168.1.101 -H example.com
  $PROGNAME -H example.com -w 200,15% -c 300,44%

Report $PROGNAME bugs to dev@sciemon.com
\c"
}

version () {
  echo -e "$PROGNAME $PVERSION
Copyright (C) 2011 Sciemon Technologies.
License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>.
This is free software: you are free to change and redistribute it.
There is NO WARRANTY, to the extent permitted by law.

Written by Marcio Pessoa <marcio@pessoa.eti.br>.
\c"
}

verify_ipaddr () {
  IPADDR=$1
  # Verify if is null
  if [ "$IPADDR" == "" ];
  then
    echo "ERROR: No host name or address specified.\n"
    help
    exit $ERROR
  fi
}

unlink_check_levels () {
  LEVEL_WARNING_T=`echo $LEVEL_WARNING | cut -f 1 -d ','`
  LEVEL_WARNING_P=`echo $LEVEL_WARNING | cut -f 2 -d ',' | tr -d '%'`
  LEVEL_CRITICAL_T=`echo $LEVEL_CRITICAL | cut -f 1 -d ','`
  LEVEL_CRITICAL_P=`echo $LEVEL_CRITICAL | cut -f 2 -d ',' | tr -d '%'`  
}

verify_time () {
  # Current value
  TIME=$1
  # Set OK values
  RETURN=$OK
  # Check if result is warning ou critical level
  if [ `echo "$TIME >= $LEVEL_WARNING_T" | bc` -eq 1 ]
  then
    STATUS="Warning"
    RETURN=$WARNING
  fi
  if [ `echo "$TIME >= $LEVEL_CRITICAL_T" | bc` -eq 1 ]
  then
    STATUS="Critical"
    RETURN=$CRITICAL
  fi
  return $RETURN;
}

verify_packet_lost () {
  # Current value
  PACKET_LOST=$1
  # Set OK values
  RETURN=$OK
  # Check if result is warning ou critical level
  if [ `echo "$PACKET_LOST >= $LEVEL_WARNING_P" | bc` -eq 1 ]
  then
    RETURN=$WARNING
  fi
  if [ `echo "$PACKET_LOST >= $LEVEL_CRITICAL_P" | bc` -eq 1 ]
  then
    RETURN=$CRITICAL
  fi
  return $RETURN;
}

get_ping_info () {
  # Ping Interface is an optional parameter
  PING_ARGS="-q "
  # Linux
  if [ "$PING_SOURCE" != "" -a "$SO" == "Linux" ];
  then
    PING_ARGS=$PING_ARGS"-I $PING_SOURCE"
  fi
  # FreeBSD
  if [ "$PING_SOURCE" != "" -a "$SO" == "FreeBSD" ];
  then
    PING_ARGS=$PING_ARGS"-S $PING_SOURCE"
  fi
  RESULT=`ping $PING_ARGS -c $PING_PACKETS -W $PING_TIMEOUT $PING_HOST | tail -2`
  RETVAL=0
  if [ $RETVAL -eq 0 ]
  then
    # Result ping packets lost
    PING_PL=`echo $RESULT | cut -f 3 -d "," | cut -f 2 -d " " | tr -d "%"`
    # Result ping averange time
    PING_AT=`echo $RESULT | cut -f 5 -d "/"`
  fi
}

main () {
  # 
  STATUS="OK"
  RETURN=$OK
  verify_ipaddr $PING_HOST
  get_ping_info
  unlink_check_levels
  verify_time $PING_AT
  STATUS_T=$?
  verify_packet_lost $PING_PL
  STATUS_P=$?
  if [ $STATUS_T -eq $WARNING -o $STATUS_P -eq $WARNING ]; then
    STATUS="Warning"
    RETURN=$WARNING
  fi
  if [ $STATUS_T -eq $CRITICAL -o $STATUS_P -eq $CRITICAL ]; then
    STATUS="Critical"
    RETURN=$CRITICAL
  fi
  echo "PING $STATUS - Packet loss = $PING_PL%, RTA = $PING_AT ms|rta="$PING_AT"ms;"$LEVEL_WARNING_T";"$LEVEL_CRITICAL_T";0.000000 pl="$PING_PL"%;"$LEVEL_WARNING_P";"$LEVEL_CRITICAL_P";0 "
  exit $RETURN
}

while [ $# -ne 0 ]; do
  case "$1" in
    --hostname | -H)
      shift
      PING_HOST=$1
      ;;
    --source | -S)
      shift
      PING_SOURCE=$1
      ;;
    --warning | -w)
      shift
      LEVEL_WARNING=$1
      ;;
    --critical | -c)
      shift
      LEVEL_CRITICAL=$1
      ;;
    --packets | -p)
      shift
      PING_PACKETS=$1
      ;;
    --timeout | -t)
      shift
      PING_TIMEOUT=$1
      ;;
    --debug | -d)
      shift
      DEBUG=$TRUE
      ;;
    --verbose | -v)
      VERBOSE=$TRUE
      ;;
    --help | -h)
      help
      version
      exit $OK
      ;;
    --version | -V)
      version
      exit $OK
      ;;
    *)
      help
      exit $UNKNOWN
      ;;
  esac
  shift
done
main
exit $UNKNOWN
