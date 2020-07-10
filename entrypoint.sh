#!/bin/bash

URL=${WEBDAV_URL:-$PLUGIN_URL}
USERNAME=${WEBDAV_USERNAME:-$PLUGIN_USERNAME}
PASSWORD=${WEBDAV_PASSWORD:-$PLUGIN_PASSWORD}

SOURCES=$PLUGIN_SOURCES

REMOTE_PATH=${PLUGIN_REMOTE_PATH:-""}

REMOTE_BASE_PATH=${PLUGIN_REMOTE_BASE_PATH:-""}
BUILD_NUMBER_PREFIX=${PLUGIN_BUILD_NUMBER_PREFIX:-"true"}
BUILD_NUMBER_PREFIX=$(echo "$BUILD_NUMBER_PREFIX" | tr '[:upper:]' '[:lower:]')
BUILD_NUMBER=${PLUGIN_BUILD_NUMER:-${DRONE_BUILD_NUMBER:-""}}
MAX_BUILD_RECORD=${PLUGIN_MAX_BUILD_RECORDE:-"10"}

set -euo pipefail

rclone config create \
    remote webdav \
    vendor other \
    url  $URL \
    user $USERNAME \
    > /dev/null 2>&1
rclone config password remote pass $PASSWORD > /dev/null 2>&1

for SPATH in $(echo "$SOURCES" | sed "s/,/ /g"); do
    if [ -d "$SPATH" ] || [ -f "$SPATH" ] ; then
        RPATH="${REMOTE_PATH}"
        
        if [ -n "$REMOTE_BASE_PATH" ] ; then
            # clone parent directory structure
            RPATH="$REMOTE_BASE_PATH"
            if [ "true" == "$BUILD_NUMBER_PREFIX" ]; then 
                RPATH="${RPATH}/${BUILD_NUMBER}"
            fi
            RPATH="${RPATH}/$(dirname $SPATH)"
        fi
        if [ -d "$SPATH" ]; then 
            # persist directory to remote
            RPATH="$RPATH/$(basename $SPATH)"
        fi
        
        echo "cloning $SPATH to remote:$RPATH"
        rclone copy $SPATH remote:$RPATH

    else
        echo "WARNING: source path $SPATH does not exist"
    fi
done


if [ -n "$REMOTE_BASE_PATH" ] && [ "true" == "$BUILD_NUMBER_PREFIX" ] && [ "$MAX_BUILD_RECORD" -eq "$MAX_BUILD_RECORD" ]  2>/dev/null ; then
    i=0
    for dir in `rclone lsf --dirs-only --dir-slash=false "remote:$REMOTE_BASE_PATH" | sort -nr`; do 
        if [ "$dir" -eq "$dir" ] 2>/dev/null ; then
            ((i=i+1))
            if  [ "$dir" -ne "$BUILD_NUMBER" ] && [ "$i" -gt "$MAX_BUILD_RECORD" ]; then 
                echo "removing remote:$REMOTE_BASE_PATH/$dir"
                rclone purge "remote:$REMOTE_BASE_PATH/$dir"
            fi
        fi
    done
fi