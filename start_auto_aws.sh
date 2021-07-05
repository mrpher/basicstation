#!/usr/bin/env bash 


###############################
# AWS IOT LORAWAN 
# More information to automate: https://docs.aws.amazon.com/iot/latest/developerguide/x509-client-certs.html
# More: https://docs.aws.amazon.com/iot-wireless/2020-11-22/apireference/API_GetWirelessGatewayCertificate.html
# More: https://iotwireless.workshop.aws/en/200_gateway/300_configureiotcorlorawan.html
# More: https://iotwireless.workshop.aws/en/700_advanced/dyigw_rak2245.html
###############################


# ###############################
# # CHECK CUPS SETTINGS
# # More info: https://iotwireless.workshop.aws/en/700_advanced/dyigw_rak2245.html
# ###############################
# if [ "$CUPS_TRUST_BASE64" == "" ]; then
#     echo -e "${WARNING_COLOR} `date -u` [WARNING] CUPS_TRUST_BASE64 variable misconfigured. Download from AWS console and copy contents of cups.trust file. ${CLEAR_COLOR}"
#     balena-idle
#     fi
# # if [ "$LNS_TRUST" == "" ]; then
# #     echo "${WARNING_COLOR} `date -u` [WARNING] LNS_TRUST variable misconfigured. Download from AWS console and copy contents of lns.trust file. ${CLEAR_COLOR}"
# #     fi
# if [ "$CUPS_CRT_BASE64" == "" ]; then
#     echo -e "${WARNING_COLOR} `date -u` [WARNING] CUPS_CRT_BASE64 variable misconfigured. Download from AWS console and copy contents of XXXXX.cert.pem file. ${CLEAR_COLOR}"
#     balena-idle
#     fi
# if [ "$CUPS_KEY_BASE64" == "" ]; then
#     echo -e "${WARNING_COLOR} `date -u` [WARNING] CUPS_KEY_BASE64 variable misconfigured. Download from AWS console and copy contents of XXXXX.private.key file. ${CLEAR_COLOR}"
#     balena-idle
#     fi
# if [ "$CUPS_URI" == "" ]; then
#     echo -e "${WARNING_COLOR} `date -u` [WARNING] CUPS_URI variable misconfigured. Copy CUPS Endpoint (URI) from AWS console. ${CLEAR_COLOR}"
#     balena-idle
#     fi

###############################
# CHECK AWS CLI CREDENTIALS 
###############################
if [ "$AWS_ACCESS_KEY_ID" == "" ]; then
    echo -e "${WARNING_COLOR} `date -u` [WARNING] AWS_ACCESS_KEY_ID variable misconfigured. Get credentials from the AWS web console. ${CLEAR_COLOR}"
    balena-idle
    fi
if [ "$AWS_SECRET_ACCESS_KEY" == "" ]; then
    echo -e "${WARNING_COLOR} `date -u` [WARNING] AWS_SECRET_ACCESS_KEY variable misconfigured. Get credentials from the AWS web console. ${CLEAR_COLOR}"
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
# TODO Fix this sx1301/1302 if statement, maybe do it before and THEN run LNS selection.
if [ "$CONCENTRATOR_MODEL" = "SX1301" ]; then
    echo "`date -u` [INFO] Gateway Concentrator: ${CONCENTRATOR_MODEL}"
    cd examples/run_aws

    ###############################
    # AWS CLI AUTOMATION 
    # More info: https://github.com/aws-samples/aws-iot-core-lorawan/tree/main/automation
    ###############################
    if [ "$AWS_DEFAULT_REGION" == "" ]; then
        echo "`date -u` [ERROR] GATEWAY_REGION variable is misconfigured. Choose us-east-1 or eu-west-1."
        balena-idle
    if [ "$LORA_REGION" == "" ]; then
        echo "`dte -u` [ERROR] LORA_REGION variable is misconfigured.  Choose US915, EU868, AU915, AS923-1."
        balena-idle

    # Create gateway
    aws iotwireless create-wireless-gateway --name balena-$BALENA_DEVICE_NAME_AT_INIT \
        --description "Gateway automatically provisioned by Balena.  https://dashboard.balena-cloud.com/devices/$BALENA_DEVICE_UUID" \
        --lorawan GatewayEui="$GATEWAY_EUI",RfRegion="$LORA_REGION" \
        --region "$AWS_DEFAULT_REGION"
        --tags Key="BALENA_DEVICE_UUID",Value="$BALENA_DEVICE_UUID" Key="BALENA_APP_ID",Value="$BALENA_APP_ID" Key="BALENA_APP_NAME",Value="$BALENA_APP_NAME" Key="BALENA_DEVICE_NAME_AT_INIT",Value="$BALENA_DEVICE_NAME_AT_INIT" Key="BALENA_DEVICE_TYPE",Value="$BALENA_DEVICE_TYPE"

    #TODO Handle creation status here.  Success or gateway already exists!
    echo "`date -u` [INFO] Created gateway in AWS with Gateway Id of $AWS_GATEWAY_ID"

    # Get Gateway Id from AWS
    AWS_GATEWAY_ID=$(aws iotwireless get-wireless-gateway \
        --identifier "$GATEWAY_EUI" \
        --identifier-type GatewayEui | jq -r .Id)

    
    # Create certificates
    AWS_CERTIFICATE_ID=$(aws iot create-keys-and-certificate \
        --set-as-active \
        --certificate-pem-outfile gateway.certificate.pem \
        --public-key-outfile gateway.public_key.pem \
        --private-key-outfile gateway.private_key.pem \
        --region $AWS_DEFAULT_REGION | jq -r .certificateId)

    echo "`date -u` [INFO] Created certificate with id $AWS_CERTIFICATE_ID"       

    # Associate gateway with new certificates
    aws iotwireless associate-wireless-gateway-with-certificate --id $AWS_GATEWAY_ID --iot-certificate-id $AWS_CERTIFICATE_ID --region $AWS_DEFAULT_REGION
                                       
    # Write trust certs to file
    # TODO Make sure these are writing to the correct folder
    aws iotwireless get-service-endpoint --service-type CUPS --region $AWS_DEFAULT_REGION | jq -r .ServerTrust > cups_server_trust.pem
    aws iotwireless get-service-endpoint --service-type LNS --region $AWS_DEFAULT_REGION | jq -r .ServerTrust > lns_server_trust.pem

    # Write cups & lns endpoints to file
    # TODO Make sure these are writing to the correct folder
    aws iotwireless get-service-endpoint --service-type CUPS --region $AWS_DEFAULT_REGION | jq -r .ServiceEndpoint > cups.uri
    aws iotwireless get-service-endpoint --service-type LNS --region $AWS_DEFAULT_REGION | jq -r .ServiceEndpoint > lns.uri

    # Use Balena API to create device tags for viewing in web ui
    curl -sX POST \
        "https://api.balena-cloud.com/v5/device_tag" \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $BALENA_API_KEY" \
        --data "{ \"device\": \"$ID\", \"tag_key\": \"AWS_GATEWAY_ID\", \"value\": \"$AWS_GATEWAY_ID\", \"tag_key\": \"AWS_CERTIFICATE_ID\", \"value\": \"$AWS_CERTIFICATE_ID\" }" > /dev/null

    # # Update AWS tags seperately 
    # # Do NOT do this step if adding tags during gateway creation.
    # aws iotwireless tag-resource \
    #     --resource-arn "arn:aws:iotwireless:us-east-1:206514182480:WirelessGateway/e0c46038-222e-438a-8c37-a0f1e2855909" \
    #     --tags Key="BALENA_DEVICE_UUID",Value="$BALENA_DEVICE_UUID" Key="BALENA_APP_ID",Value="$BALENA_APP_ID" Key="BALENA_APP_NAME",Value="$BALENA_APP_NAME" Key="BALENA_DEVICE_NAME_AT_INIT",Value="$BALENA_DEVICE_NAME_AT_INIT" Key="BALENA_DEVICE_TYPE",Value="$BALENA_DEVICE_TYPE"


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
