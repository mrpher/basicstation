#!/usr/bin/env bash

### 1. RETRIEVE GATEWAY EUI ###
# Get the MAC address from Linux and modify it to add the LoRa convention 
# of "FFFE" to the middle.  Finish off with an uppercase output and echo it to screen.
TAG_KEY="GATEWAY_EUI"
GATEWAY_EUI=$(cat /sys/class/net/eth0/address | sed -r 's/[:]+//g' | sed -e 's#\(.\{6\}\)\(.*\)#\1fffe\2#g' | tr [:lower:] [:upper:])
echo "Gateway EUI: $GATEWAY_EUI" # TODO: move all echos to a final output including all configurations?

### 2. GET DEVICE ID FROM BALENA API ###
# Call the Balena API to return the device ID for step 3.
ID=$(curl -sX GET "https://api.balena-cloud.com/v5/device?\$filter=uuid%20eq%20'$BALENA_DEVICE_UUID'" \
-H "Content-Type: application/json" \
-H "Authorization: Bearer $BALENA_API_KEY" | \
jq ".d | .[0] | .id")

### 3. SET DEVICE TAG WITH GATEWAY EUI ###
# Take the device ID returned above and use it to add the tag key:value to the
# correct device in Balena web console.
TAG=$(curl -sX POST \
"https://api.balena-cloud.com/v5/device_tag" \
-H "Content-Type: application/json" \
-H "Authorization: Bearer $BALENA_API_KEY" \
--data "{ \"device\": \"$ID\", \"tag_key\": \"$TAG_KEY\", \"value\": \"$GATEWAY_EUI\" }" > /dev/null)

### 4. CHECK DEVICE MODEL VARIABLE ###
if [ -z ${MODEL} ] ;
 then
    echo -e "[WARNING]: MODEL variable not set.\n Set the model of the gateway you are using (SX1301 or SX1302)."
    balena-idle
 else
    if [ "$MODEL" = "SX1301" ] || [ "$MODEL" = "RAK2245" ] || [ "$MODEL" = "iC880a" ]; 
    then
        echo "Using MODEL: $MODEL" # TODO: move all echos to a final output including all configurations?
        #!/usr/bin/env bash 

        # LNS_SERVICE=${LNS_SERVICE:-2}

        if [ $LNS_SERVICE == "AWS" ]; 
        then
            echo -e "[INFO] LNS_SERVICE is set to AWS, retreive your TC_URI (LNS Endpoint URL) and xxx from AWS LoRaWAN console."
            # TC_URI= 
            # TC_TRUST=${TC_TRUST:-$(curl --silent "https://letsencrypt.org/certs/trustid-x3-root.pem.txt")}

        elif [ $LNS_SERVICE == "TTS" ]; 
        then
            echo -e "[INFO] LNS_SERVICE is set to TTS, retreive your TC_URI (LNS Endpoint URL) and xxx from your TTS console."
            # TC_URI=
            # TC_TRUST=${TC_TRUST:-$(curl --silent "https://letsencrypt.org/certs/{trustid-x3-root.pem.txt,isrgrootx1.pem}")}
        
        elif [ $LNS_SERVICE == "TTN" ]; 
        then
            echo -e "[INFO] LNS_SERVICE is set to AWS, retreive your TC_URI (LNS Endpoint URL) and xxx from the TTN console."
            # SET TTN information

        else
            echo -e "[ERROR] LNS_SERVICE variable is incorrectly configured, should be either AWS, TTS, or TTN!"
            balena-idle
        fi

        # Check configuration
        if [ "$TC_URI" == "" ] || [ "$TC_TRUST" == "" ]
        then
            echo -e "[ERROR] Missing configuration, define either LNS_SERVICE or TC_URI and TC_TRUST."
            balena-idle
        fi

        echo "Server: $TC_URI" # TODO: move all echos to a final output including all configurations?

        # Sanitize TC_TRUST
        #TC_TRUST=$(echo $TC_TRUST | sed 's/-----BEGIN CERTIFICATE-----/-----BEGIN CERTIFICATE-----\n/' | sed 's/-----END CERTIFICATE-----/\n-----END CERTIFICATE-----/' | sed 's/\n\n/\n/g')

        # declare map of hardware pins to GPIO on Raspberry Pi
        declare -a pinToGPIO
        pinToGPIO=( -1 -1 -1 2 -1 3 -1 4 14 -1 15 17 18 27 -1 22 23 -1 24 10 -1 9 25 11 8 -1 7 0 1 5 -1 6 12 13 -1 19 16 26 20 -1 21)
        GW_RESET_PIN=${GW_RESET_PIN:-11}
        GW_RESET_GPIO=${GW_RESET_GPIO:-${pinToGPIO[$GW_RESET_PIN]}}
        LORAGW_SPI=${LORAGW_SPI:-"/dev/spidev0.0"}

        # Change to project folder
        cd examples/live-s2.sm.tc

        # Setup TC files from environment
        echo "$TC_URI" > tc.uri
        echo "$TC_TRUST" > tc.trust
        if [ ! -z ${TC_KEY} ]; then
            echo "Authorization: Bearer $TC_KEY" | perl -p -e 's/\r\n|\n|\r/\r\n/g'  > tc.key
        fi

        # Reset gateway
        echo "Resetting gateway concentrator on GPIO $GW_RESET_GPIO"
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
    fi


    if [ "$MODEL" = "SX1302" ] || [ "$MODEL" = "RAK2287" ]; 
    then
        # ./start_sx1302.sh
        # TODO: Add logic here.
    fi
fi

#balena-idle
