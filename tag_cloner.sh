#!/bin/bash
#------------------------------------------------------
# Mostly copied from: https://www.lostserver.com/static/nfc-cloner.sh
# Inspiration video: https://www.youtube.com/watch?v=c0Qsmgvj_oo
#------------------------------------------------------
# NFC Card reader/writer used: ACR122U-A9 
#------------------------------------------------------
# 31/01/25 - First Version
#------------------------------------------------------

clear
cat <<EOF               
     /\            
    /  \__   _____ 
   / /\ \ \ / / _ \ 
  / ____ \ V /  __/
 /_/    \_\_/ \___| TAG CLONER
                   
 Cuz I'm a trash bin hacker now


EOF

#-----------------------------------------------

# Check for root privileges
if [ $(/usr/bin/id -u) -ne 0 ]; then 
    echo " ### ERROR: You must run this script with sudo or as root!"
    exit 1
fi

# Check if necessary utilities are installed
ANTICOL="/usr/bin/nfc-anticol"       # for reading the UID
NFC_SETUID="/usr/bin/nfc-mfsetuid"   # for writing the UID

for UTIL in ${ANTICOL} ${NFC_SETUID}; do 
    if [ ! -x ${UTIL} ]; then 
        echo " ### ERROR: Utility ${UTIL} not found!"
        echo " Please install the necessary utilities with the following commands:"
        echo " sudo apt-get install libnfc-examples"
        exit 1
    fi
done

# Function to detect and read card UID
function read_card_uid() {
    echo "Place the card to read on the NFC reader..."
    while true; do
        DATA="$(${ANTICOL} 2>&1)"
        if [[ ! "$DATA" =~ "Error: No tag available" ]]; then
            CARD_UID=$(echo "${DATA}" | grep "UID:" | awk '{print $2}')
            if [ -n "$CARD_UID" ]; then
                echo "Card UID: ${CARD_UID}"
                return 0
            fi
        fi
        sleep 1
    done
}

# Function to write UID to new card
function write_card_uid() {
    local UID_TO_WRITE=$1
    echo "Place the blank card on the NFC writer..."
    while true; do
        DATA="$(${ANTICOL} 2>&1)"
        if [[ ! "$DATA" =~ "Error: No tag available" ]]; then
            NEW_CARD_UID=$(echo "${DATA}" | grep "UID:" | awk '{print $2}')
            if [ -n "$NEW_CARD_UID" ]; then
                echo "Writing UID: ${UID_TO_WRITE} to new card..."
                ${NFC_SETUID} ${UID_TO_WRITE}
                if [ $? -eq 0 ]; then
                    echo "UID written successfully!"
                    return 0
                else
                    echo " ### ERROR: Failed to write UID!"
                    exit 1
                fi
            fi
        fi
        sleep 1
    done
}

# Main Script Flow
read_card_uid
ORIGINAL_UID=$CARD_UID
${NFC_MFCLASSIC} w a ${CARD_FILE}

# Prompt to clone
echo 'Remove the card'
read -r -p "Do you want to clone this UID to another card? (y/n): " response
if [[ "$response" =~ ^([yY][eE][sS]|[yY])+$ ]]; then
    write_card_uid $ORIGINAL_UID
else
    echo "Operation canceled."
    exit 0
fi

echo "UID cloning completed."
