#!/bin/bash

RTMP_SERVER="rtmp://global-live.mux.com:5222/app/"

COMMAND="/usr/bin/ffmpeg"

while test $# -gt 0
do
    T="$1"
    if [ "${1:0:32}" == "rtmp://a.rtmp.youtube.com/live2/" ]; then
        # T  will contain the rtmp key from jitsi meet page
        COMMAND="$COMMAND $RTMP_SERVER${T:32}"
    else
        COMMAND="$COMMAND $T"
    fi
    shift
done

echo "Running replaced ffmpeg: «$COMMAND»."

exec $COMMAND
PROCESS_FFMPEG=$!

echo "Waiting for process: ${PROCESS_FFMPEG}."
wait $PROCESS_FFMPEG
