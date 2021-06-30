#!/usr/bin/env bash

###############################
# SET ECHO COLORS 
###############################
ERROR_COLOR="\033[31m"
WARNING_COLOR="\033[33m"
CLEAR_COLOR="\033[0m"

echo "`date -u` [INFO] Initiating Basicstation setup ..."

###############################
# GET GATEWAY EUI FROM ETH0
###############################
GATEWAY_MAC=$(cat /sys/class/net/eth0/address | sed -r 's/[:]+//g' | tr [:lower:] [:upper:])
GATEWAY_EUI=$(cat /sys/class/net/eth0/address | sed -r 's/[:]+//g' | sed -e 's#\(.\{6\}\)\(.*\)#\1fffe\2#g' | tr [:lower:] [:upper:])
echo "`date -u` [INFO] Gateway MAC: $GATEWAY_MAC"
echo "`date -u` [INFO] Gateway EUI: $GATEWAY_EUI"

###############################
# GET DEVICE ID FROM API 
###############################
ID=$(curl -sX GET "https://api.balena-cloud.com/v5/device?\$filter=uuid%20eq%20'$BALENA_DEVICE_UUID'" \
-H "Content-Type: application/json" \
-H "Authorization: Bearer $BALENA_API_KEY" | \
jq ".d | .[0] | .id")

###############################
# SET GATEWAY EUI WITH API 
###############################
TAG=$(curl -sX POST \
"https://api.balena-cloud.com/v5/device_tag" \
-H "Content-Type: application/json" \
-H "Authorization: Bearer $BALENA_API_KEY" \
--data "{ \"device\": \"$ID\", \"tag_key\": \"GATEWAY_EUI\", \"value\": \"$GATEWAY_EUI\" }" > /dev/null)

###############################
# SET BASICSTATION LOGS 
###############################
# IMPORTANT! station.conf by default is pseudo jason.  
# It must be converted to real json in order for jq to work.

if [ "$BASICSTATION_LOG_FILE" == "" ]; then
    echo -e "[WARNING] No BASICSTATION_LOG_FILE configured. Defaulting to 'stderr'."
    BASICSTATION_LOG_FILE="stderr"
    jq -e '.station_conf.log_file="'$BASICSTATION_LOG_FILE'"' station.conf > station.conf.tmp && cp station.conf.tmp station.conf && rm station.conf.tmp
fi
jq -e '.station_conf.log_file="'$BASICSTATION_LOG_FILE'"' station.conf > station.conf.tmp && cp station.conf.tmp station.conf && rm station.conf.tmp
echo "[INFO] Set log_file in station.conf to $BASICSTATION_LOG_FILE."

# Then set the log level
if [ "$BASICSTATION_LOG_LEVEL" == "" ]; then
    echo -e "[WARNING] No BASICSTATION_LOG_LEVEL configured. Defaulting to 'DEBUG'. Options are XDEBUG, DEBUG, VERBOSE, INFO, NOTICE, WARNING, ERROR, or CRITICAL."
    BASICSTATION_LOG_LEVEL="DEBUG"
    jq -e '.station_conf.log_level="'$BASICSTATION_LOG_LEVEL'"' station.conf > station.conf.tmp && cp station.conf.tmp station.conf && rm station.conf.tmp
fi
jq -e '.station_conf.log_level="'$BASICSTATION_LOG_LEVEL'"' station.conf > station.conf.tmp && cp station.conf.tmp station.conf && rm station.conf.tmp
echo "[INFO] Set log_level in station.conf to $BASICSTATION_LOG_LEVEL."

###############################
# CHECK LNS_SERVICE VARIABLE
###############################
if [ $LNS_SERVICE == ""]; then
	echo "${WARNING_COLOR} `date -u` [WARNING] No LNS_SERVICE variable configured. Please choose AWS, TTS, or TTN. ${CLEAR_COLOR}"
elif [ $LNS_SERVICE == "AWS" ]; then
	echo "`date -u` [INFO] LNS_SERVICE is set to AWS, retreive your TC_URI (LNS Endpoint URL) and xxx from AWS LoRaWAN console."
    ./start_aws.sh
elif [ $LNS_SERVICE == "TTS" ]; then
	echo "`date -u` [INFO] LNS_SERVICE is set to TTS, retreive your TC_URI (LNS Endpoint URL) and xxx from your TTS console."
	./start_tts.sh
elif [ $LNS_SERVICE == "TTN" ]; then
	echo "`date -u` [INFO] LNS_SERVICE is set to AWS, retreive your TC_URI (LNS Endpoint URL) and xxx from the TTN console."
	./start_ttn.sh
elif [ $LNS_SERVICE == "CHRP" ]; then
	echo "`date -u` [INFO] LNS_SERVICE is set to Chipstack.. etc etc"
    ./start_chrp.sh
else
    echo "${ERROR_COLOR} `date -u` [ERROR] LNS_SERVICE is incorrectly configured, should be either AWS, TTS, or TTN! ${CLEAR_COLOR}"
	balena-idle
fi

balena-idle
