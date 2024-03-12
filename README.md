# Bluetooth Library Patcher
_Licensed under the terms of the GNU General Public License v3.0._

## What does it do?
This script patches the bluetooth library to avoid losing bluetooth pairings after a reboot or airplane mode switch on rooted samsung devices.
Like [the module](https://github.com/3arthur6/BluetoothLibraryPatcher), it should support libraries from most samsung devices running Android 7.0-14.

## How to use?
On a Linux or WSL system with xxd installed, run:

```./bt-lib-patcher.sh <lib/apex> <api> [arm/qcom]```

It will output the patched library to `out/`, and saves the original library to `out/stock/` if you provided an apex.

## Credits:
- **[@3arthur6](https://github.com/3arthur6)** for the [BluetoothLibraryPatcher module](https://github.com/3arthur6/BluetoothLibraryPatcher), which this script is hugely based on
- **[@duhansysl](https://github.com/duhansysl)** for [his script](https://github.com/duhansysl/Bluetooth-Library-Patcher)
