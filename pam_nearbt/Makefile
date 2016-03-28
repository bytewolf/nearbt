prefix=/usr/local

install:
	xcodebuild clean install -project ../pam_nearbt.xcodeproj -target pam_nearbt -configuration Release DSTROOT=$(prefix)
	xcodebuild clean install -project ../pam_nearbt.xcodeproj -target pam_nearbt-setup -configuration Release DSTROOT=$(prefix)

.PHONY: install

