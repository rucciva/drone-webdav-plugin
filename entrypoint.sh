#!/bin/sh

set -e

URL=${WEBDAV_URL:-$PLUGIN_URL}
USERNAME=${WEBDAV_USERNAME:-$PLUGIN_USERNAME}
PASSWORD=${WEBDAV_PASSWORD:-$PLUGIN_PASSWORD}
RPATH=$PLUGIN_REMOTE_PATH
SOURCES=$PLUGIN_SOURCES

rclone config create \
    remote webdav \
    vendor other \
    url  $URL \
    user $USERNAME \
    > /dev/null 2>&1

rclone config password remote pass $PASSWORD > /dev/null 2>&1

for SPATH in $(echo "$SOURCES" | sed "s/,/ /g"); do
    if [ -d "$SPATH" ] || [ -f "$SPATH" ] ; then
        rclone copy $SPATH remote:$RPATH/$(basename $SPATH) -v -P
    else
        echo "WARNING: source path $SPATH does not exist"
    fi
done
