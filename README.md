NearBT
======

A pluggable authentication module (PAM) on OS X for local authentication with iOS devices (NearBT installed) via Bluetooth LE.

With NearBT, you can,
---------------------

- Unlock OS X screen saver without typing password. *No need to store your password.*
- Add an extra authentication to log in OS X in addition to password. It works like two-factor authentication.

It contains,
------------

* An iOS app -- `NearBT`
* A pluggable authentication module (PAM) on OS X -- `pam_nearbt.so`
* A command line setup tool -- `pam_nearbt-setup`

Installation
------------

- Open `NearBT.xcodeproj` in Xcode, build and run NearBT on your iOS devices.
- Open `pam_nearbt-installer.pkg` and complete the installation.
- Open Terminal, run `pam_nearbt-setup` and follow the instructions.
