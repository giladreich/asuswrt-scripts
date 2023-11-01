#!/bin/sh
# Made by Jack'lul <jacklul.github.io>
#
# Download files from netboot.xyz to specified directory
#
# Based on:
#  https://github.com/RMerl/asuswrt-merlin.ng/wiki/Enable-PXE-booting-into-netboot.xyz
#

#shellcheck disable=SC2155

readonly SCRIPT_PATH="$(readlink -f "$0")"
readonly SCRIPT_NAME="$(basename "$SCRIPT_PATH" .sh)"
readonly SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"
readonly SCRIPT_CONFIG="$SCRIPT_DIR/$SCRIPT_NAME.conf"
readonly SCRIPT_TAG="$(basename "$SCRIPT_PATH")"

FILES="netboot.xyz.efi netboot.xyz.kpxe" # what files to download, space separated
DIRECTORY="/tmp/netboot.xyz" # where to save the files
BASE_URL="https://boot.netboot.xyz/ipxe/" # base download URL, with ending slash

if [ -f "$SCRIPT_CONFIG" ]; then
    #shellcheck disable=SC1090
    . "$SCRIPT_CONFIG"
fi

case "$1" in
    "run")
        { [ "$(nvram get wan0_state_t)" != "2" ] && [ "$(nvram get wan1_state_t)" != "2" ]; } && { echo "WAN network is not connected"; exit; }
        ! wget -q --spider "http://boot.netboot.xyz" && { echo "Cannot reach netboot.xyz server"; exit 1; }

        [ ! -d "$DIRECTORY" ] && mkdir -p "$DIRECTORY"

        DOWNLOADED=""
        for FILE in $FILES; do
            [ -f "$DIRECTORY/$FILE" ] && continue

            if curl -fsSL "$BASE_URL$FILE" -o "$DIRECTORY/$FILE"; then
                DOWNLOADED="$DOWNLOADED $FILE"
            else
                logger -st "$SCRIPT_TAG" "Failed to download: $BASE_URL$FILE"
            fi
        done

        cru d "$SCRIPT_NAME"
        [ -n "$DOWNLOADED" ] && logger -st "$SCRIPT_TAG" "Downloaded files from netboot.xyz: $(echo "$DOWNLOADED" | xargs)"
    ;;
    "start")
        cru a "$SCRIPT_NAME" "$CRON_MINUTE $CRON_HOUR * * * $SCRIPT_PATH run"
    ;;
    "stop")
        cru d "$SCRIPT_NAME"
    ;;
    "restart")
        sh "$SCRIPT_PATH" stop
        sh "$SCRIPT_PATH" start
    ;;
    *)
        echo "Usage: $0 run|start|stop|restart"
        exit 1
    ;;
esac