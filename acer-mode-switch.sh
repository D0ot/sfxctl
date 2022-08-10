#!/bin/bash

MODE=$(sudo ec_probe read 16 | cut -d ' ' -f 1)

MODE_STR=""

NEXT_MODE_VAL=""
NEXT_MODE_STR=""

case "$MODE" in
	2) MODE_STR="Slient"
	;;
	3) MODE_STR="Performance"
	;;
	0) MODE_STR="Normal"
	;;
	*) echo "Unknow Current MODE Value:${MODE}, exit without changing anything"
		exit 1
	;;
esac

echo "Current Mode: $MODE_STR"

FAN_SPEED=$(sudo ec_probe read 20 | cut -d ' ' -f 1)
echo "Fan speed values: $FAN_SPEED"

STAMP_LIMIT=0
FAST_LIMIT=0
SLOW_LIMIT=0

case "$1" in
	0|"Normal"|"normal"|"n") NEXT_MODE_STR="Normal"; NEXT_MODE_VAL=0
        STAMP_LIMIT=35000; FAST_LIMIT=35000; SLOW_LIMIT=35000;
	;;
	2|"Silent"| "silent"| "s") NEXT_MODE_STR="Silent"; NEXT_MODE_VAL=2
        STAMP_LIMIT=10000; FAST_LIMIT=10000; SLOW_LIMIT=10000;
	;;
	3|"Performance"| "Performance"| "p") NEXT_MODE_STR="Performance"; NEXT_MODE_VAL=3
        STAMP_LIMIT=50000; FAST_LIMIT=50000; SLOW_LIMIT=50000;
	;;
	"max"|"m") sudo ec_probe write 34 8; echo "Maximize fan speed"; exit 0
	;;
    "")
        exit 0
    ;;
	*) echo "Unknow Input Mode : "$1", exit without changing anything."
		exit 2
	;;
esac

sudo ec_probe write 34 0
echo "Switch to $NEXT_MODE_STR Mode"
echo "Mode Value is $NEXT_MODE_VAL"

sudo ec_probe write 16 $NEXT_MODE_VAL
sleep 1
sudo ryzenadj -a $STAMP_LIMIT -b $FAST_LIMIT -c $SLOW_LIMIT
