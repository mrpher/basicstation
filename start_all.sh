#!/usr/bin/env bash

###############################
# SET ECHO COLORS 
###############################
ERROR_COLOR="\033[31m"
WARNING_COLOR="\033[33m"
CLEAR_COLOR="\033[0m"

echo -e "[INFO] Initiating Basicstation setup ..."

###############################
# GET GATEWAY EUI 
###############################
GATEWAY_MAC=$(cat /sys/class/net/eth0/address | sed -r 's/[:]+//g' | tr [:lower:] [:upper:])
GATEWAY_EUI=$(cat /sys/class/net/eth0/address | sed -r 's/[:]+//g' | sed -e 's#\(.\{6\}\)\(.*\)#\1fffe\2#g' | tr [:lower:] [:upper:])
echo "[INFO] Gateway MAC: $GATEWAY_MAC"
echo "[INFO] Gateway EUI: $GATEWAY_EUI"

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
# CHECK MODEL VARIABLE 
###############################
if [ -z ${MODEL} ] ;
 then
    echo -e "[WARNING] MODEL variable not set. Set the model of the gateway you are using (SX1301 or SX1302)."
    balena-idle
 else
    if [ "$MODEL" = "SX1301" ] || [ "$MODEL" = "RAK2245" ] || [ "$MODEL" = "iC880a" ]; 
    then
        echo -e "[INFO] Gateway Concentrator: SX1301"
        ./start_sx1301.sh
    if [ "$MODEL" = "SX1302" ] || [ "$MODEL" = "RAK2287" ]; 
    then
        echo -e "[INFO] Gateway Concentrator: SX1302"
        ./start_sx1302.sh
    fi
fi

#balena-idle
