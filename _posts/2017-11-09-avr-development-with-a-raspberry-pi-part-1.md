---
title: AVR development part 1
subtitle: Setting up the Raspberry Pi
tags:
  - avr
  - raspberry
  - electronics
  - hello-avr
series: hello-avr
date: 2017-11-09 17:59:31 +0100
---

> As I the days start to grow darker again, I was looking around for some interesting things to do with all the electronic 'crap' I have lying around and about in the house, and I came up with writing a series of post covering the setup of a [Raspberry Pi2](https://en.wikipedia.org/wiki/Raspberry_Pi) to use it as a developing environment for [AVR microcontrollers](https://en.wikipedia.org/wiki/Atmel_AVR).

This post will cover the initial setup of a Raspberry Pi, if you already have Raspbian running on your device you can skip to the next post in the series:  - put link -. When finished, you'll have a Raspberry Pi running Raspbian and are able to remotely the Raspberry Pi via ssh.

**prerequisites**
* Raspberry Pi (I used a RPI 2 model B)
* Raspberry Pi is connected to the web
* Installation of [Etcher](https://etcher.io/) on host machine to flash the SD card
* SD card to hold our image

### Preparing a Raspbian image

We'll start by getting the latest Raspbian image from [raspberrypi.org](https://www.raspberrypi.org/downloads/raspbian/) this can take a while so enjoy your favorite beverage. On your host machine, once the image is downloaded and with your SD card plugged in open up Etcher and just follow the wizard.

I will use a headless (no peripheral attached) Raspberry Pi setup so after Etcher has finished its job but *before* you swap the SD card to the Raspberry, add a file named `ssh` to the root of your SD card (when mounted on a Mac, in linux it appears as a '/boot' partition/dir on the card). The content of this file can be left empty but for good measure and my future self I added a comment to it that states the files purpose, such as:
```
# existence of this file enables ssh on the Raspberry Pi.
```
This will enable us to login to the Pi remotely via ssh.

### Configuring Raspbian

We can now eject the SD card from our host machine, insert it into the Raspberry and boot it up.
Assuming the Raspberry has a network connection, you can then login to it via ssh by running something the following command from out host machine.
``` bash
$ ssh pi@raspberrypi.local
```
Where the part after the '@' might differ if you have a different image or have configured another hostname for the Pi.

In case you cannot connect, you can try to find the RPI by running
``` bash
$ nmap -sn 192.168.178.0/24
```
This would return a list of devices connected to your network.

When you're ssh'd into your Pi we first need to configure some basics and for this you can use the
`raspi-config` cli tool by running
``` bash
$ sudo raspi-config
```
It will open a menu from which you can easily change some config parameters of the Pi. I usually choose: **7 Advanced Options** and then in the submenu I'd choose **A1** to make sure all SD card storage is available to the Pi. I leave exploring the other options as an exercise to the readers.

To make your Pi easier to access without having to type a password each time you can have a look at
the 'Passwordless ssh' entry in the sources at the end of this post. Do note that if you password protect you ssh key (which I'd recommend), you'd still need to type a password everytime unless your ssh client is configured to 'remember' is for a certain session.

### Installing software

On a plain Raspbian image there are a lot of basic unix tools already available, but I'd like some more! In headless environments I usually use vim for editing files, and to install it on the Rapberry we'd do this
```
$ sudo apt-get update # to update package sources
$ sudo apt-get install vim # to install e.g vim
```
We will need to install more packages during this series, but for now vim will be enough.
The next post in this series will explain how to setup and configure the AVR tools.

### Extra: troubleshooting

* wifi

  My Pi is connected to the interwebs via an Edimax wifi dongle and I noticed some problems with the connectivity, it would seem to take quite some time before the ssh connection would be established after not using it for a couple of minutes. This is caused by the power saving option that will put the dongle to sleep after a certain time. Supposedly, it could be fixed by disabling this feature.
  ```
  $ lsusb # Check usb devices
  $ lsmod # Check kernel modules
  $ sudo vim /etc/modprobe.d/8192cu.conf

  # Content of /etc/modprobe.d/8192cu.conf
  #
  # Disable power management
  options 8192cu rtw_power_mgnt=0 rtw_enusbss=0
  ```
  this should keep the dongle from going into sleep mode (I still notice delay).

  The second tip I tried was just connecting with the ip address directly and that seemed to have more effect. You can try to find your Pi's ip from a host computer by running something similar to `nmap -sn 192.168.1.0/24` on your host. It will list hostnames and respective ip addresses of the 192.168.1.x network.

  Also, try setting `UseDNS=no` in **/etc/ssh/sshd_config** and restart the ssh deamon with `/etc/init.d/ssh restart`.

### Sources

* [Where I heard about Etcher first](https://blog.alexellis.io/getting-started-with-docker-on-raspberry-pi/)
* [Passwordless ssh (on raspberry.org)](https://www.raspberrypi.org/documentation/remote-access/ssh/passwordless.md)
* [Enabling wifi (on raspberrypi.org)](https://www.raspberrypi.org/documentation/configuration/wireless/wireless-cli.md)
