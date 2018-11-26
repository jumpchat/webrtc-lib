#!/bin/bash

AR=ar
RANLIB=ranlib
WEBRTC_LIB=$1
WEBRTC_BUILD_DIR=$2

function help {
    echo "$0 [webrtc-lib] [webrtc-build-path]"
    echo "Example:"
    echo " % $0 libwebrtc.a webrtc/src/out/Release"
}

if [ "$WEBRTC_LIB" == "" ] || [ "$WEBRTC_BUILD_DIR" == "" ]; then
    help
    exit
fi

if [ "${OS}" == "Windows_NT" ]; then
    find ${WEBRTC_BUILD_DIR} -name '*.obj' -or -name '*.o' | egrep -v '.*(examples|protobuf_full|yasm/gen|yasm/re2c|yasm/yasm)' > ${WEBRTC_BUILD_DIR}/libwebrtc.rsp
    lib /out:${WEBRTC_LIB} @${WEBRTC_BUILD_DIR}/libwebrtc.rsp
    rm ${WEBRTC_BUILD_DIR}/libwebrtc.rsp
fi

if [ `uname -s` == "Linux" ]; then
    find ${WEBRTC_BUILD_DIR} -name '*.o' | egrep -v '.*(examples|protobuf_full|yasm/gen|yasm/re2c|yasm/yasm|buildtools)' | xargs ar cq ${WEBRTC_LIB}
    ${RANLIB} ${WEBRTC_LIB}
fi

if [ `uname -s` == "Darwin" ]; then
    find ${WEBRTC_BUILD_DIR} -name '*.o' | egrep -v '.*(examples|protobuf_full|yasm/gen|yasm/re2c|yasm/yasm)' > ${WEBRTC_BUILD_DIR}/libwebrtc.rsp
    libtool -static -o ${WEBRTC_LIB} -no_warning_for_no_symbols -filelist ${WEBRTC_BUILD_DIR}/libwebrtc.rsp
    strip ${WEBRTC_LIB}
    rm ${WEBRTC_BUILD_DIR}/libwebrtc.rsp
fi
