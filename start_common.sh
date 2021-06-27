# Options are AWS, TTS (open source The Things Stack), or TTN (default v3)
# No default option, this variable is required!

# LNS_SERVICE=${LNS_SERVICE:-2}
if [ $LNS_SERVICE == ""]; then
	echo -e "[WARNING] No LNS_SERVICE variable configured. Please choose AWS, TTS, or TTN."
elif [ $LNS_SERVICE == "AWS" ]; then
	echo -e "[INFO] LNS_SERVICE is set to AWS, retreive your TC_URI (LNS Endpoint URL) and xxx from AWS LoRaWAN console."
	# TC_URI= 
	# TC_TRUST=${TC_TRUST:-$(curl --silent "https://letsencrypt.org/certs/trustid-x3-root.pem.txt")}
elif [ $LNS_SERVICE == "TTS" ]; then
	echo -e "[INFO] LNS_SERVICE is set to TTS, retreive your TC_URI (LNS Endpoint URL) and xxx from your TTS console."
	# TC_URI=
	# TC_TRUST=${TC_TRUST:-$(curl --silent "https://letsencrypt.org/certs/{trustid-x3-root.pem.txt,isrgrootx1.pem}")}
elif [ $LNS_SERVICE == "TTN" ]; then
	echo -e "[INFO] LNS_SERVICE is set to AWS, retreive your TC_URI (LNS Endpoint URL) and xxx from the TTN console."
	# SET TTN information
else
    echo -e "[ERROR] LNS_SERVICE is incorrectly configured, should be either AWS, TTS, or TTN!"
	balena-idle
fi

# Check configuration
if [ "$TC_URI" == "" ] || [ "$TC_TRUST" == "" ]
then
    echo -e "[ERROR] Missing configuration, define either LNS_SERVICE or TC_URI and TC_TRUST.\033[0m"
	balena-idle
fi

echo "Server: $TC_URI"

# Sanitize TC_TRUST
#TC_TRUST=$(echo $TC_TRUST | sed 's/-----BEGIN CERTIFICATE-----/-----BEGIN CERTIFICATE-----\n/' | sed 's/-----END CERTIFICATE-----/\n-----END CERTIFICATE-----/' | sed 's/\n\n/\n/g')

# declare map of hardware pins to GPIO on Raspberry Pi
declare -a pinToGPIO
pinToGPIO=( -1 -1 -1 2 -1 3 -1 4 14 -1 15 17 18 27 -1 22 23 -1 24 10 -1 9 25 11 8 -1 7 0 1 5 -1 6 12 13 -1 19 16 26 20 -1 21)
GW_RESET_PIN=${GW_RESET_PIN:-11}
GW_RESET_GPIO=${GW_RESET_GPIO:-${pinToGPIO[$GW_RESET_PIN]}}
LORAGW_SPI=${LORAGW_SPI:-"/dev/spidev0.0"}
