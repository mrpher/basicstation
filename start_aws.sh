#!/usr/bin/env bash 


###############################
# AWS IOT LORAWAN 
# More information to automate: https://docs.aws.amazon.com/iot/latest/developerguide/x509-client-certs.html
# More: https://docs.aws.amazon.com/iot-wireless/2020-11-22/apireference/API_GetWirelessGatewayCertificate.html
# More: https://iotwireless.workshop.aws/en/200_gateway/300_configureiotcorlorawan.html
# More: https://iotwireless.workshop.aws/en/700_advanced/dyigw_rak2245.html
###############################

###############################
# CHECK TC SETTINGS
###############################
# if [ "$TC_TRUST" == "" ]; then
#     echo "${WARNING_COLOR} `date -u` [WARNING] No TC_TRUST configured. ${CLEAR_COLOR}"
#     fi
# if [ "$TC_KEY" == "" ]; then
#     echo "${WARNING_COLOR} `date -u` [WARNING] No TC_KEY configured. ${CLEAR_COLOR}"
#     fi
# if [ "$TC_CRT" == "" ]; then
#     echo "${WARNING_COLOR} `date -u` [WARNING] No TC_CRT configured. ${CLEAR_COLOR}"
#     fi
# if [ "$TC_URI" == "" ]; then
#     echo "${WARNING_COLOR} `date -u` [WARNING] No TC_URI configured. ${CLEAR_COLOR}"
#     fi

# balena-idle

###############################
# CHECK CUPS SETTINGS
# More info: https://iotwireless.workshop.aws/en/700_advanced/dyigw_rak2245.html
###############################
# TODO Make logic of CUPS vs LNS choice more intuitive? ie. If AWS_URI is cups then do not require LNS_TRUST, if AWS_URI is lns/wss do not require CUPS_TRUST?
if [ "$CUPS_TRUST_BASE64" == "" ]; then
    echo -e "${WARNING_COLOR} `date -u` [WARNING] CUPS_TRUST_BASE64 variable misconfigured. Download from AWS console and copy contents of cups.trust file. ${CLEAR_COLOR}"
    balena-idle
    fi
# if [ "$LNS_TRUST" == "" ]; then
#     echo "${WARNING_COLOR} `date -u` [WARNING] LNS_TRUST variable misconfigured. Download from AWS console and copy contents of lns.trust file. ${CLEAR_COLOR}"
#     fi
if [ "$CUPS_CRT_BASE64" == "" ]; then
    echo -e "${WARNING_COLOR} `date -u` [WARNING] CUPS_CRT_BASE64 variable misconfigured. Download from AWS console and copy contents of XXXXX.cert.pem file. ${CLEAR_COLOR}"
    balena-idle
    fi
if [ "$CUPS_KEY_BASE64" == "" ]; then
    echo -e "${WARNING_COLOR} `date -u` [WARNING] CUPS_KEY_BASE64 variable misconfigured. Download from AWS console and copy contents of XXXXX.private.key file. ${CLEAR_COLOR}"
    balena-idle
    fi
if [ "$CUPS_URI" == "" ]; then
    echo -e "${WARNING_COLOR} `date -u` [WARNING] CUPS_URI variable misconfigured. Copy CUPS Endpoint (URI) from AWS console. ${CLEAR_COLOR}"
    balena-idle
    fi

###############################
# SET COMMON HARDWARE PINS/GPIO 
###############################
declare -a pinToGPIO
pinToGPIO=( -1 -1 -1 2 -1 3 -1 4 14 -1 15 17 18 27 -1 22 23 -1 24 10 -1 9 25 11 8 -1 7 0 1 5 -1 6 12 13 -1 19 16 26 20 -1 21)
if [ "$GW_RESET_PIN" == "" ]; then
    echo -e "`date -u` [WARNING] GW_RESET_PIN variable is misconfigured. Defaulting to 11"
    GW_RESET_PIN=11
else
    GW_RESET_PIN=${GW_RESET_PIN}
fi
GW_RESET_GPIO=${GW_RESET_GPIO:-${pinToGPIO[$GW_RESET_PIN]}}
LORAGW_SPI=${LORAGW_SPI:-"/dev/spidev0.0"}

###############################
# CHECK CONCENTRATOR_MODEL VARIABLE 
###############################
if [ "$CONCENTRATOR_MODEL" = "SX1301" ]; then
    echo "`date -u` [INFO] Gateway Concentrator: ${CONCENTRATOR_MODEL}"
    cd examples/run_aws

    # Be sure to base64 encode the certs BEFORE entering into variables.
    # Example: base64 cups.crt > cups.crt.base64 && base64 cups.trust > cups.trust.base64 && base64 cups.key > cups.key.base64
    # Which will create files in the same folder.  Open, copy contents, and past into Balena variables. 
    # OR base64 cups.crt and copy result one by one from the terminal.
    echo $CUPS_TRUST_BASE64 | base64 --decode > cups.trust
    echo $CUPS_CRT_BASE64 | base64 --decode > cups.crt
    echo $CUPS_KEY_BASE64 | base64 --decode > cups.key

    echo "$CUPS_URI" > cups.uri

    echo "`date -u` [INFO] GW_RESET_PIN is set to ${GW_RESET_PIN}"
    echo "`date -u` [INFO] GPIO_RESET_PIN is set to ${GW_RESET_GPIO}"
    echo "`date -u` [INFO] Resetting gateway concentrator to pick up settings ..."
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
    echo "`date -u`[INFO] CONCENTRATOR_MODEL is set to ${CONCENTRATOR_MODEL}"
    echo -e "${ERROR_COLOR} `date -u` [ERROR] SX1302 is not supported - YET :) ${CLEAR_COLOR}"
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

    balena-idle # TODO Remove when SX1302 is fixed.
else
    echo -e "${WARNING_COLOR} `date -u` [WARNING] CONCENTRATOR_MODEL variable misconfigured. Please choose SX1301 or SX1302. ${CLEAR_COLOR}"
    balena-idle
fi

