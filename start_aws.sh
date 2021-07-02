#!/usr/bin/env bash 

###############################
# AWS IOT LORAWAN 
# More information to automate: https://docs.aws.amazon.com/iot/latest/developerguide/x509-client-certs.html
###############################

###############################
# CHECK TRUST CERTIFICATES 
###############################
if [ "$TC_TRUST" == "" ]; then
    echo "${WARNING_COLOR} `date -u` [WARNING] No TC_TRUST configured. ${CLEAR_COLOR}"
    fi
if [ "$TC_KEY" == "" ]; then
    echo "${WARNING_COLOR} `date -u` [WARNING] No TC_KEY configured. ${CLEAR_COLOR}"
    fi
if [ "$TC_CRT" == "" ]; then
    echo "${WARNING_COLOR} `date -u` [WARNING] No TC_CRT configured. ${CLEAR_COLOR}"
    fi
if [ "$TC_URI" == "" ]; then
    echo "${WARNING_COLOR} `date -u` [WARNING] No TC_URI configured. ${CLEAR_COLOR}"
    fi

balena-idle

###############################
# SET HARDWARE PINS/GPIO 
###############################
declare -a pinToGPIO
pinToGPIO=( -1 -1 -1 2 -1 3 -1 4 14 -1 15 17 18 27 -1 22 23 -1 24 10 -1 9 25 11 8 -1 7 0 1 5 -1 6 12 13 -1 19 16 26 20 -1 21)
GW_RESET_PIN=${GW_RESET_PIN:-11}
GW_RESET_GPIO=${GW_RESET_GPIO:-${pinToGPIO[$GW_RESET_PIN]}}
LORAGW_SPI=${LORAGW_SPI:-"/dev/spidev0.0"}

###############################
# CHECK CONCENTRATOR_MODEL VARIABLE 
###############################
if [ "$CONCENTRATOR_MODEL" = "SX1301" ]; then
    echo "`date -u` [INFO] Gateway Concentrator: ${CONCENTRATOR_MODEL}"
    cd examples/live-s2.sm.tc

    echo "$TC_CRT" > tc.crt
    echo "$TC_KEY" > tc.key
    echo "$TC_TRUST" > tc.trust
    echo "$TC_URI" > tc.uri

    echo "`date -u` [INFO] Resetting gateway concentrator on GPIO $GW_RESET_GPIO"
    echo $GW_RESET_GPIO > /sys/class/gpio/export
    echo out > /sys/class/gpio/gpio$GW_RESET_GPIO/direction
    echo 0 > /sys/class/gpio/gpio$GW_RESET_GPIO/value
    sleep 1
    echo 1 > /sys/class/gpio/gpio$GW_RESET_GPIO/value
    sleep 1
    echo 0 > /sys/class/gpio/gpio$GW_RESET_GPIO/value
    sleep 1
    echo $GW_RESET_GPIO > /sys/class/gpio/unexport
    RADIODEV=$LORAGW_SPI ../../build-rpi-std/bin/station

elif [ "$CONCENTRATOR_MODEL" = "SX1302" ]; then
    echo "`date -u`[INFO] Gateway Concentrator: ${CONCENTRATOR_MODEL}"
    echo "`date -u` [WARNING] SX103 is not supported - YET :)"
    # cd examples/corecell
    # # Setup TC files from environment
    # # TODO Fix echo destination for AWS
    # echo "$TC_URI" > ./lns-ttn/tc.uri
    # echo "$TC_TRUST" > ./lns-ttn/tc.trust
    # if [ ! -z ${TC_KEY} ]; then
    #     echo "Authorization: Bearer $TC_KEY" | perl -p -e 's/\r\n|\n|\r/\r\n/g'  > ./lns-ttn/tc.key
    # fi

    # # Set other environment variables
    # export GW_RESET_GPIO=$GW_RESET_GPIO
    # ./start-station.sh -l ./lns-ttn
else
    echo "${WARNING_COLOR} `date -u` [WARNING] CONCENTRATOR_MODEL variable misconfigured. Please choose SX1301 or SX1302. ${CLEAR_COLOR}"
    balena-idle
fi

