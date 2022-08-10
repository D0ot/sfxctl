#!/bin/env sh

BAT_PATH="/sys/class/power_supply/BAT1"

echo "scale=3; $(cat ${BAT_PATH}/voltage_now ).0 /1000000.0 * $(cat ${BAT_PATH}/current_now ).0 /1000000.0" | bc
