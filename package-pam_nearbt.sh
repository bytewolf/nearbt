#!/bin/bash

TEMP_DIR=`mktemp -d /tmp/nearbt-XXXXXXXXX`

xcodebuild clean install -project pam_nearbt.xcodeproj -target pam_nearbt -configuration Release DSTROOT="${TEMP_DIR}"

xcodebuild clean install -project pam_nearbt.xcodeproj -target pam_nearbt-setup -configuration Release DSTROOT="${TEMP_DIR}"

pkgbuild --root "${TEMP_DIR}" \
    --identifier "name.guoc.pam_nearbt" \
    --version "0.1.1" \
    --install-location "/usr/local" \
    "pam_nearbt.pkg"

rm -rf "${TEMP_DIR}"

productsign --sign "Developer ID Installer: Chen Guo (46J35R76NH)" \
    "pam_nearbt.pkg" "pam_nearbt-signed.pkg"
