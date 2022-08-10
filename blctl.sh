#!/bin/env sh
readonly BRIGHTNESS_WRITE="/sys/class/backlight/amdgpu_bl0/brightness"
readonly BRIGHTNESS_READ="/sys/class/backlight/amdgpu_bl0/actual_brightness"

print_cur()
{
    local cur_bl=$(cat ${BRIGHTNESS_READ})
    echo "Current brightness : $cur_bl / 255"
}

main () 
{
    if [ $# -gt 1 ]
    then
        echo "Too much args"
        exit 1
    fi

    if [ $# -eq 0 ]
    then
        print_cur
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

main "$@"

