#!/bin/bash

sudo xcodebuild clean build install -project pam_nearbt.xcodeproj -target pam_nearbt -configuration Release DSTROOT=/usr/local
sudo xcodebuild clean build install -project pam_nearbt.xcodeproj -target pam_nearbt-setup -configuration Release DSTROOT=/usr/local
