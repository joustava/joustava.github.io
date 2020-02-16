---
title: Onion Omega and BLE
description: Setting up an Onion Omega as BlueTooth LE beacon
tags:
  - BLE
  - Bluetooth
  - OnionOmega
  - OpenWRT
  - IoT
date: 2016-08-10 12:54:32
---
A while back I backed the [Onion Omega](https://onion.io/) on Kickstarter and I finally received all the components.
One of the first things I tried was setting it up as a BLE Beacon in order to learn a little about the subject.
BLE Beacons or Bluetooth Low Energy Beacons are devices that periodically send data packages over the Bluetooth protocol. Beacons come in various types and brands. Many beacons just send a particular UUID which the supporting system can then map to e.g a location or event. There are also Beacons that are able to send additional data such as weather data. This tutorial only covers setting up the Onion Omega as a basic BLE Beacon via the command line.

### Before you start

Make sure you have the following ready for use.

* Onion Omega
* Onion Omega dock
* BLE USB dongle (needs to be supported by the [bluez](http://www.bluez.org/) library version found from [OpenWRT](https://www.openwrt.org/) repositories)

On first use the Onion Omega needs to be added to the same wifi as your development machine to make development easier, it is then possible to manage the device remotely via ssh. In order to do this you need to connect to its Access Point (AP) via wifi and access the onion Omega its pages via the browser via e.g http://omega-ABCD.local/. The Onion Omega Setup Wizard will lead you through the steps and once your done you should be able ssh into it while being on your regular office/home network (e.g ssh root@omega-ABCD.local). If you haven't set up ssh please do so by following
[Adding your Public Key to the Omega](https://wiki.onion.io/Tutorials/Adding-Public-Key-to-Omega) tutorial. When done correctly you should be able to connect to the Onion Omega according to the [Connect to the Omega via SSH](https://wiki.onion.io/Tutorials/Connecting-to-Omega-via-SSH) tutorial without having to type your password.

While not necessary for this tutorial it might also be a very good idea to secure your AP with WPA2.

### Installing dependencies

First we'll check for a firmware update
```
$ oupgrade -check
$ opkg update # If needed
```
Then we'll install the needed BLE libraries
```
$ opkg install obluez-libs obluez-utils
```
This might take a while and takes around a whopping 3Mb of the devices total internal RAM of about 15Mb.

### Testing the BLE dongle

After installing the needed packages we should check if the BLE device is detected. **hcitool** is a command line utility that we can use for this purpose. After connecting the BLE dongle to the Onion Omegas USB port we should be able to detect it with
```
$ hciconfig hci0 -a
hci0:	Type: BR/EDR  Bus: USB
	BD Address: 00:1A:7D:DA:71:13  ACL MTU: 310:10  SCO MTU: 64:8
	DOWN
	RX bytes:564 acl:0 sco:0 events:29 errors:0
	TX bytes:358 acl:0 sco:0 commands:29 errors:0
```
The output my vary but the main point is that it is found and that is flagged as being DOWN. In order to bring the BLE device UP we can run the following commands
```
$ hciconfig hci0 up
$ hciconfig hci0 leadv 3
$ hciconfig hci0 noscan
```
This will bring the HCI device UP, enables LE advertising and disables page and inquiry scanning.
These settings will not make its name advertised, leadv 0 will, but we do not need this.
The set of commands will also automatically set the advertising rate to the slower default of 1280ms.
We can check if the BLE device is up and running
```
$ hciconfig hci0 -a
hci0:	Type: BR/EDR  Bus: USB
	BD Address: 00:1A:7D:DA:71:13  ACL MTU: 310:10  SCO MTU: 64:8
	UP RUNNING
	RX bytes:1176 acl:0 sco:0 events:66 errors:0
	TX bytes:1072 acl:0 sco:0 commands:66 errors:0
```

### Configuring the Advertised data

The data that the Beacon sends can be configured by using **hcitool**, for example we can set a payload that is conforming the
[AltBeacon specification](https://github.com/AltBeacon/spec)
```
$ hcitool -i hci0 cmd \
 0x08 \ # A
 0x0008 \ # B
 1E \ # C
 02 \ # D
 01 \ # E
 1A \ # F
 1B \ # G
 FF \ # H
 0A 00 \ # I
 BE AC \ # J,K
 E2 0A 39 F4 73 F5 4B C4 A1 2F 17 D1 AD 07 A9 61 \ # L
 0C 0E \ # M
 0C 0E \ # N
 C8 \ # O
 00 # P
```
A short description of the field payload, check the [AltBeacon specification](https://github.com/AltBeacon/spec) for details
```
Byte sequence:

A. Groups OCF commands for LE Controllers.
B. Set advertising data command
C. Number of bytes that follow in the advertisement    
D. Number of bytes that follow in first AD structure
E. Flags AD type    
F. Flags value 0x1A = 000011010   
    bit 0 (OFF) LE Limited Discoverable Mode
    bit 1 (ON) LE General Discoverable Mode
    bit 2 (OFF) BR/EDR Not Supported
    bit 3 (ON) Simultaneous LE and BR/EDR to SDC (controller)
    bit 4 (ON) Simultaneous LE and BR/EDR to SDC (Host)
G. AD LENGTH
H. Manufacturer specific data AD TYPE    
I. MFG ID (0x004C == Apple, 0x000A == Cambridge Silicon Radio)
   0A     Company identifier code LSB
   00     Company identifier code MSB
J. BE     Byte 0 of BEACON CODE - 0xBEAC in case of altbeacon.
K. AC     Byte 1 of BEACON CODE

L. BEACON ID First 16 bytes for organizational unit
M. BEACON ID Second 2 bytes (e.g for individual stores, etc.)
N. BEACON ID Third  2 bytes (e.g for nodes within one location, etc.)
O. REFERENCE RSSI
P. MFG RESERVED
```

The 128-bit uuid could be generated with the built in dbus-uuidgen tool found on Onion Omega OpenWRT.
```
$ dbus-uuidgen
2d 1c 63 6f e4 f8 0c 63 38 dd 47 79 57 38 8a e7
```

### Setting Beacon Advertising rate

In order to set the advertising rate we need to set the Advertising Parameters.
```
$ hcitool -i hci0 cmd \
  0x08 0x0006 A0 00 A0 00 03 00 00 00 00 00 00 00 00 07 00
  #           |A    |B    |C |
```
A. A0 00		min interval (0.625ms granularity)
B. A0 00 		max interval (0.625ms granularity)
C. 03				advertising mode (to non-connectable in this case)

This example sets the time between advertisements to 100ms.

The granularity of this setting is 0.625ms so setting the interval to 01 00 sets the advertisement to go every 0.625ms. Setting it to A0 00 sets the advertisement to go every 0xA0 * 0.625ms = 100ms. Setting it to 40 06 sets the advertisement to go every 0x0640 * 0.625ms = 1000ms. With a non-connectable advertisement, the fastest you can advertise is 100ms, with a connectable advertisment (0x00) you can advertise much faster.

We need to enable advertisement with `hcitool` instead of `hciconfig`, because `hciconfig hci0 leadv 3` will automatically set the advertising rate to a default of 1280ms.
```
$ hcitool -i hci0 cmd 0x08 0x000a 01
```

### Scanning for beacons

There are several ways to test if our BLE Beacon is actually advertising. I'll only cover how to scan for beacons with Android and with a RaspberryPi.

* Android

  A simple solution to check if BLE devices are broadcasting their data is by using an Android device with Bluetooth enabled and e.g one of these [android tools](http://altbeacon.org/examples/) installed. There are several others BLE apps to be found on the Play store, pick the one that suits you.

* RPI

  By using a Raspberry Pi with the Raspberry Linux distribution and a BLE dongle attached we can scan for devices in the neighbourhood by using `hcitool`.

  ```
  $ sudo hcitool lescan
  LE Scan ...
  00:1A:7D:DA:71:13 (unknown)
  38:01:95:01:5E:41 (unknown)
  00:1A:7D:DA:71:13 rpi2
  ```
  After configuring a new BLE Beacon as descibed above, I can see it by scanning again.
  ```
  $ sudo hcitool lescan
  LE Scan ...
  ```

  The Raspberry Pi itself can also be configured as a BLE beacon in a similar way as the Onion Omega, the only difference is that the [bluez](http://www.bluez.org/) toolset needs to be installed. Setting up a RPI as BLE might be somewhat of an overkill, though.

### Bluetooth Tools summary

The following tools may or may not be available on your chosen beacon system,
I list them here however for reference.

* **bccmd**        issue BlueCore commands to Cambridge Silicon Radio devices. (Yei!)
* **bluemoon**     Bluemoon configuration utility.
* **bluetoothctl** interactive Bluetooth control program.
* **bluetoothd**   Bluetooth daemon.
* **btmon**        provides access to the Bluetooth subsystem monitor infrastructure for reading HCI traces.
* **ciptool**      set up, maintain, and inspect the CIP configuration of the Bluetooth subsystem in the Linux kernel.
* **hciattach**    attach a serial UART to the Bluetooth stack as HCI transport interface.
* **hciconfig**    configure Bluetooth devices.
* **hcidump**      reads raw HCI data coming from and going to a Bluetooth device and prints to screen commands, events and data in a human readable form.
* **hcitool**      configure Bluetooth connections and send some special command to Bluetooth devices.
* **hex2hcd**      convert a file needed by Broadcom devices to hcd (Broadcom bluetooth firmware) format.
* **l2ping**       send a L2CAP echo request to the Bluetooth MAC address given in dotted hex notation.
* **l2test**       L2CAP testing program.
* **rctest**       test RFCOMM communications on the Bluetooth stack.
* **rfcomm**       set up, maintain, and inspect the RFCOMM configuration of the Bluetooth subsystem in the Linux kernel.
* **sdptool**      perform SDP queries on Bluetooth devices.

*libbluetooth.so contains the BlueZ 4 API functions.*

### Sources

* [BLE](https://en.wikipedia.org/wiki/Bluetooth_low_energy)
* [BLE Beacons](http://www.ti.com/lit/an/swra475/swra475.pdf)
* [BLE vs RFID](http://blog.beaconstac.com/2015/10/rfid-vs-ibeacon-ble-technology/)
* [AltBeacon Specification](http://altbeacon.org/)
* [Bluez](http://www.bluez.org/)
* [RPI iBeacon](https://learn.adafruit.com/pibeacon-ibeacon-with-a-raspberry-pi/adding-ibeacon-data)
* [RSSI](https://en.wikipedia.org/wiki/Received_signal_strength_indication)
* [Android Beacon Support](https://altbeacon.github.io/android-beacon-library/index.html)
* [TI SensorTag](http://processors.wiki.ti.com/index.php/SensorTag2015)
* [Bluetooth core Specs](https://www.bluetooth.com/specifications/bluetooth-core-specification)
* ~~[OSX Beacon scanning](http://www.hugeinc.com/ideas/perspective/an-ibeacon-scanning-utility-for-osx)~~
* [How iBeacons Work](http://www.warski.org/blog/2014/01/how-ibeacons-work/)
* [iBeacon profile](http://stackoverflow.com/questions/18906988/what-is-the-ibeacon-bluetooth-profile)
* [Beacon tracking with node](https://medium.com/truth-labs/beacon-tracking-with-node-js-and-raspberry-pi-794afa880318#.y6u9g76hc)
* [BLE Tutorials_and_Training](https://wiki.csr.com/wiki/Main_Page#Tutorials_and_Training)
* [BLE Advertising primer](http://www.argenox.com/bluetooth-low-energy-ble-v4-0-development/library/a-ble-advertising-primer/)
