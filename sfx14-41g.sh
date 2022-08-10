#!/bin/env sh

readonly BAT_PATH="/sys/class/power_supply/BAT1"

readonly GPU_OFF_METHOD="\_SB.PCI0.GPP0.PG00._OFF"
readonly GPU_ON_METHOD="\_SB.PCI0.GPP0.PG00._ON"
readonly ACPI_CALL_PATH="/proc/acpi/call"
readonly PCIE_GPP_BRIDGE_PM='/sys/bus/pci/devices/0000:00:01.1/power/control'

readonly BRIGHTNESS_WRITE="/sys/class/backlight/amdgpu_bl0/brightness"
readonly BRIGHTNESS_READ="/sys/class/backlight/amdgpu_bl0/actual_brightness"

test_root () {
    # test root privilege -- rc: 0=root, 1=not root
    [ "$(id -u)" = "0" ]
}

check_root () {
    # show error message and quit when root privilege missing
    if ! test_root; then
        echo "Error: missing root privilege." 1>&2
        exit 1
    fi
}


run_acpi_method ()
{
    echo $1 | sudo tee $ACPI_CALL_PATH > /dev/null
    sudo cat $ACPI_CALL_PATH
}

# disable auto power managemnent
gpu_bridge_pm_set ()
{
    echo "$1" | sudo tee $PCIE_GPP_BRIDGE_PM > /dev/null
}

gpu_bridge_pm_get ()
{
    sudo cat $PCIE_GPP_BRIDGE_PM
}

gpu ()
{

    cmd=""
    case "$1" in
        "ON"|"on")
            cmd=$GPU_ON_METHOD
        ;;
        "OFF"|"off")
            cmd=$GPU_OFF_METHOD
        ;;
        *)
            echo "no valid args." 2>&1
            exit 1
        ;;
    esac

    sudo modprobe acpi_call

    pm=$(gpu_bridge_pm_get)
    gpu_bridge_pm_set "on"

    run_acpi_method $GPU_OFF_METHOD > /dev/null

    retval=$(run_acpi_method $cmd)

    gpu_retval=0
    case "$retval" in
        Error*)
            echo "ACPI CALL FAILED"
            echo "return value: $retval"
            gpu_retval=1
        ;;

        *)
            echo "ACPI CALL SUCCESS"
            echo "return value: $retval"
        ;;
    esac

    gpu_bridge_pm_set "$pm"
    exit $gpu_retval

}

blctl_print_cur()
{
    local cur_bl=$(cat ${BRIGHTNESS_READ})
    echo "Current brightness : $cur_bl / 255"
}

blctl ()
{
    if [ $# -gt 1 ]
    then
        echo "Too much args"
        exit 1
    fi

    if [ $# -eq 0 ]
    then
        blctl_print_cur
        exit 1
    fi

    local cur_bl=$(cat ${BRIGHTNESS_READ})

    local val=$(echo $1 | bc)


    local new_bl=$(echo "$val + $cur_bl" | bc)

    if [ $new_bl -gt 255 ]
    then
        new_bl=255
    fi

    if [ $new_bl -lt 0 ]
    then
        new_bl=0
    fi

    echo $new_bl | tee ${BRIGHTNESS_WRITE}
}

bl ()
{
    case "$1" in
        "up"|"Up"|"UP"|"u")
            blctl "10"
        ;;
        "down"|"d"|"Down"|"DOWN")
            blctl "-10"
        ;;
        *)
            echo "no valid args." 2>&1
            exit 1
        ;;
    esac

}

acer_mode_switch()
{
    local MODE=$(sudo ec_probe read 16 | cut -d ' ' -f 1)
    local MODE_STR=""

    local NEXT_MODE_VAL=""
    local NEXT_MODE_STR=""

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

    local FAN_SPEED=$(sudo ec_probe read 20 | cut -d ' ' -f 1)
    echo "Fan speed values: $FAN_SPEED"

    local STAMP_LIMIT=0
    local FAST_LIMIT=0
    local SLOW_LIMIT=0
    
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
}

mode ()
{
    acer_mode_switch $@
}



power_get()
{
    echo "scale=3;\
        $(cat ${BAT_PATH}/voltage_now ).0 /1000000.0 *\
        $(cat ${BAT_PATH}/current_now ).0 /1000000.0" | bc
}

power_log()
{
    if [ "$1" = "" ]
    then
        target=300
    else
        case $1 in
            *[!0-9]*)
                echo "./sfx14-41g.sh power log [num]" 2>&1
                echo "num is not valid"
                exit 1
            ;;

            *)
                target=${1}
            ;;
        esac
    fi
    count=0
    while [ $count -lt $target ]; do
	    sleep 2
	    power_get
        count=$(($count+1))
    done
}

power ()
{
    case "$1" in
        get)
            power_get
        ;;
        log)
            shift 1
            power_log $@
        ;;
        *)
            power_get
        ;;
    esac

}


main_help(){
    echo 'Usage: sfx14-14g.sh [subcommand] args....
Avaliable subcommands:
    bl, Backlight control
    mode, Acer Mode switch
    gpu, control the gpu power
    power, get or log the power ' 2>&1
}

main ()
{
    if [ $# -lt 1 ]
    then
        main_help
        exit 1
    fi

    subcmd=$1
    shift 1
    case "$subcmd" in
        mode|m)
            mode $@
        ;;
        gpu|g)
            gpu $@
        ;;
        bl|b)
            bl $@
        ;;
        power|p)
            power $@
        ;;
        help|h)
            main_help
            exit 0
        ;;
        *)
            echo "\"${subcmd}\" is not a valid subcommand." 2>&1
            main_help
            exit 1
        ;;
    esac


}


main $@
