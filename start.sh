#!/usr/bin/env bash

###############################
# SET ECHO COLORS 
###############################
ERROR_COLOR="\033[31m"
WARN_COLOR="\033[33m"
CLEAR_COLOR="\033[0m"


###############################
# GET GATEWAY EUI FROM ETH0
###############################
# TODO How to make this visible to Datadog tags?  Datadog container WONT have mmcli 
GATEWAY_MAC=$(cat /sys/class/net/eth0/address | sed -r 's/[:]+//g' | tr [:lower:] [:upper:])
GATEWAY_EUI=$(cat /sys/class/net/eth0/address | sed -r 's/[:]+//g' | sed -e 's#\(.\{6\}\)\(.*\)#\1fffe\2#g' | tr [:lower:] [:upper:])
echo "`date -u` [INFO] Initiating Basicstation setup with Gateway EUI: $GATEWAY_EUI based on eth0 MAC Address: $GATEWAY_MAC ..."


###############################
# GET MODEM DETAILS
###############################
# TODO How to make this visible to Datadog tags?  Datadog container WONT have mmcli 
# MODEM_IMEI=$(mmcli -m 0 --output-json | jq '.modem.generic."equipment-identifier" | tonumber')
# MODEM_MODEL=$(mmcli -m 0 --output-json | jq '.modem.generic.model')
# # MODEM_STATUS=
# # MODEM_NETWORK=
# echo "`date -u` [INFO] Modem IMEI: $MODEM_IMEI"
# echo "`date -u` [INFO] Modem Model: $MODEM_MODEL"


###############################
# CHECK LNS_SERVICE VARIABLE
###############################
if [ $LNS_SERVICE == "AWS" ]; then
    echo -e "`date -u` [INFO] LNS_SERVICE is set to AWS IoT LoRaWAN."
    ./start_aws.sh
elif [ $LNS_SERVICE == "AUTOAWS" ]; then
	echo -e "`date -u` [INFO] LNS_SERVICE is set to Auto AWS IoT LoRaWAN."
	./start_auto_aws.sh
elif [ $LNS_SERVICE == "TTS" ]; then
	echo -e "`date -u` [INFO] LNS_SERVICE is set to The Things Stack."
	./start_tts.sh
elif [ $LNS_SERVICE == "TTN" ]; then
	echo -e "`date -u` [INFO] LNS_SERVICE is set to The Things Network."
	./start_ttn.sh
elif [ $LNS_SERVICE == "CHRP" ]; then
	echo -e "`date -u` [INFO] LNS_SERVICE is set to Chirpstack."
    ./start_chrp.sh
else
    echo -e "${ERROR_COLOR} `date -u` [ERROR] LNS_SERVICE variable misconfigured. Valid options are AWS, AUTOAWS, TTS, TTN, or CHRP. ${CLEAR_COLOR}"
	balena-idle
fi

balena-idle
