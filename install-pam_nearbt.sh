#!/bin/bash

LIBOATH_SOURCE_PATH="/usr/local/lib/liboath.dylib"
LIBOATH_LOCAL_PATH="./pam_nearbt/liboath.dylib"
LIBOATH_INSTALL_PATH="/usr/local/lib/pam_nearbt/liboath.dylib"

if [ ! -e "./pam_nearbt/liboath.dylib" ]
then
    cp "$LIBOATH_SOURCE_PATH" "$LIBOATH_LOCAL_PATH"
fi

sudo install_name_tool -id "$LIBOATH_INSTALL_PATH" "$LIBOATH_LOCAL_PATH"

sudo cp "$LIBOATH_LOCAL_PATH" "$LIBOATH_INSTALL_PATH"

sudo xcodebuild clean build install -project pam_nearbt.xcodeproj -target pam_nearbt -configuration Release DSTROOT=/
