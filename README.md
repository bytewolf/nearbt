NearBT
======

A pluggable authentication module (PAM) on OS X for local authentication with iOS devices (NearBT installed) via Bluetooth LE.

With NearBT, you can,
---------------------

- Unlock OS X screen saver without typing password (just type return). *No need to store your password.*
- Add an extra authentication to log in OS X in addition to password. It works like two-factor authentication.
- Also works on authentication dialogs when you make changes on some preferences, and `sudo` command in Terminal.

Features
--------

### Security

* OS X passwords are not saved somewhere regardless of whether passwords are encrypted.
* iOS device identifiers are used in Bluetooth connections.
* Bluetooth pairing is required.
* Time-based One-time Password Algorithm ([TOTP](https://en.wikipedia.org/wiki/Time-based_One-time_Password_Algorithm)) is used to authenticate.
* Open source for both OS X and iOS.

### Energy

* Only create a connection when an authentication starts. Stop the connection once the authentication finishes.
* Thanks to Bluetooth Low Energy, it's about 1% in 7 days from iOS's battery usage report.

### Customization

* Minimum RSSI (received signal strength indicator). Higher values reduce the valid scope of iOS devices.
* Run scripts when authentication begins or if authentication succeeds or fails.

Run `pam_nearbt-setup parameters` for more details.

Compatibility
-------------

- OS X (>= 10.10)
- iOS (>= 9)

---

- MacBook (>= 2015)
- MacBook Air (>= 2011)
- MacBook Pro (>= 2012)
- Mac Mini (>= 2011)
- Mac Pro (>= 2013)
- iMac (>= 2012)

---

- iPhone (>= 4S)
- iPad (>= 4th gen)
- iPad mini
- iPad Air
- iPod Touch (>= 5th gen)

It contains,
------------

* An iOS app -- `NearBT`
* A pluggable authentication module (PAM) on OS X -- `pam_nearbt.so`
* A command line setup tool -- `pam_nearbt-setup`

Uninstallation
--------------

Know how to uninstall it before installation.

0. Remove related configuration lines in /etc/pam.d/ before uninstallation.

1. Remove installed files.
  ```
  sudo rm /usr/local/lib/security/pam_nearbt.so
  sudo rm /usr/local/bin/pam_nearbt-setup
  ```

2. If you want to remove all configuration files,
  ```
  rm ~/.config/pam_nearbt/peripheral
  rm ~/.config/pam_nearbt/secret
  sudo rm /usr/local/etc/pam_nearbt/peripheral
  sudo rm /usr/local/etc/pam_nearbt/secret
  ```
  If you have set other secret path in the PAM's parameters, remember to remove it.

Installation
------------

- Download NearBT-iOS-version.zip and pam_nearbt-signed-version.pkg from [latest release](http://github.com/guoc/nearbt/releases/latest)
- Extract NearBT-iOS-version.zip and open `NearBT.xcodeproj` in Xcode, build and run NearBT on your iOS devices.
- Open `pam_nearbt-signed-version.pkg` and complete the installation.
- Open Terminal, run `pam_nearbt-setup` and follow the instructions.
- For available PAM parameters, run `pam_nearbt-setup parameters`.

Alternatives
------------

### iOS and OS X

- [Knock](http://www.knocktounlock.com)
- [*MacID*](http://macid.co)
- [Near Lock](http://nearlock.me)
- [Tether](http://www.hellotether.com)

### Other

- libpam-blue
- [BlueProximity](http://blueproximity.sourceforge.net)
