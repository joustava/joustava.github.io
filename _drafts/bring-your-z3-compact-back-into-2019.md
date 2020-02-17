---
title: Sony xperia Z3 Compact back to the Future!
description: bring your Z3 Compact back into 2020
tags: 
  - Sony
  - Z3
  - TWRP
---

**This guide is to help you updating your old Android device and a XPERIA Z3 model in particular. However, it is your decision to install the software on your device. I take no responsibility for any damage that may occur from installing custom firmware or tools on your device.**

## Aquire an Unlocking Code for the device

https://developer.sony.com/develop/open-devices/get-started/unlock-bootloader/how-to-unlock-bootloader/

and unlock your phone with the code according to their walkthrough.

## Install tools

When on a mac you need to have `adb` and `fastboot` installed. These come with the Android SDK. These tools we use to add a package to a startup partition of the phone via usb. We would only need the SDK platform-tools to get `adb` and `fastboot` binaries, but as I had already an installation of the Android SDK I used the tools from that installation.

## Download dependencies

1. [TWRP recovery tool](https://twrp.me/) # tool we use to install the new images.
2. [Open Google Apps](https://opengapps.org/) # application packages/play store (choose: arm - 8.1 - nano for basic config)
3. [CarbonROM Android firmware](https://carbonrom.org/) # os.

The last two dependencies need to be available on the phone in order for us to install them with twrp. The easiest
is to use an SD card that is compatible with the device. Then you can upload the zip files via a card reader connected to your computer to
then place it back into the Z3C.

## Development mode

**Important**
Make sure the phone is in development mode (tapping 7 times in system menu).

## Install TWRP

The following steps will install the TWRP recovery image on your device.

1. Disconnect USB
2. Power off phone (and wait 10 - 15 seconds)
3. Keep `VOLUME UP` pressed
4. Connect USB
5. Release VOLUME UP when blue notification light lights up.
6. run: `fastboot flash FOTAKernel ~/Downloads/TWRP_3.2.3-0/recovery.img`

The path is just an example. Make sure you point the path to where you downloaded the dependencies.
After these steps you should be able to boot the device into TWRP tool. You would do this by following steps 1 - 4
THIS TIME pressing `VOLUME DOWN` and release it when TWRP is shown on screen.

**Please read [this blog post](https://android.gadgethacks.com/how-to/ultimate-guide-using-twrp-only-custom-recovery-youll-ever-need-0156006/) on the features of TWRP.**

## Make a backup of the old system!

with TWRP

## Clear data

with TWRP

## Install Carbon and OpenGapp

with TWRP, you can chose both zips first and then flash the device.
