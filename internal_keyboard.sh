#!/bin/bash

# This script is used to disable/enable the internal keyboard
# Usage: ./internal_keyboard.sh [enable|disable]

if [[ $# -ne 1 ]]; then
    echo "Usage: ./internal_keyboard.sh [enable|disable]"
    exit 1
fi

if [[ $1 != "enable" && $1 != "disable" ]]; then
    echo "Usage: ./internal_keyboard.sh [enable|disable]"
    exit 1
fi


# Get the number of internal keyboard
number=$(xinput | grep AT | grep -E -o "[0-9]+" | head -2 | tail -1)

# if the number is empty, exit
if [[ -z $number ]]; then
    echo "Internal keyboard not found"
    exit 1
# if the number is not empty, disable/enable the internal keyboard
else
    if [[ $1 == "disable" ]]; then
        xinput float $number
        echo "Internal keyboard disabled"
    elif [[ $1 == "enable" ]]; then
        xinput reattach $number 3
        echo "Internal keyboard enabled"
    fi
fi