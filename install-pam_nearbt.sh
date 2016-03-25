#!/bin/bash

sudo xcodebuild clean build install -project pam_nearbt.xcodeproj -target pam_nearbt -configuration Release DSTROOT=/
