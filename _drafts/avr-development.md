---
title: hello-avr
draft: true
#abbrlink: 16774
date: 2017-11-01 20:39:55
tags:
---

1) setup environment (mac) `brew cask install crosspack-avr`
this will include simulavr (not working out of the box?)

[hello-avr docker debug env for attiny85](https://bitbucket.org/joustava/hello-avr)

2) create a project `avr-project hello-avr`

3) Check what chip you want to use, I ordered 5 `ATTINY85-20PU` -> `attiny85`
4) Find datasheet for reference

5) Pin layout

1 - * - 8
2 -   - 7
3 -   - 6
4 -   - 5

I/O
*Pin x - (modes)*
Pin 1 - (PCINT5/RESET/ADC0/dW) PB5
Pin 2 - (PCINT3/XTAL1/CLKI/OC1B/ADC3) PB3
Pin 3 - (PCINT4/XTAL2/CLKO/OC1B/ADC2) PB4
Pin 4 - GND
Pin 5 - (MOSI/DI/SDA/AIN0/OC0A/OC1A/AREF/PCINT0) PB0
Pin 6 - (MISO/DO/AIN1/OC0B/OC1A/PCINT1) PB1
Pin 7 - (SCK/USCK/SCL/ADC1/T0/INT0/PCINT2) PB2
Pin 8 - VCC

In order to do somethign with these ports we also need to know about some other registers
DDRx – Port x Data Direction Register (0 = in, 1 = out) configure corresponding pins as input or output
PORTx – Port x Data Register (write to corresponding pin when pin is OUT or set corresponding pin pullup resistors when IN)
PINx – Port B Input Pins Register (Read from port pins)
-- only using the above for now
MCUCR – MCU Control Register
GIMSK – General Interrupt Mask Register
PCMSK – Pin Change Mask Register
GIFR – General Interrupt Flag Register

So our registers are named DDRB, PORTB and PINB.
Single pins are addresses by DDB0..DDB5
Single port input pins are addressed by PIN0...PIN5
The controller in question has only one Port, B


6) Operating Voltage
  2.7 - 5.5V for ATtiny25/45/85

7) Programmer
show supported `avrdude -c .`

AVRISP mkII -> avrisp2 = Atmel AVR ISP mkII

8) Fuses (w fusecalc)
-U lfuse:w:0x62:m -U hfuse:w:0xdf:m -U efuse:w:0xff:m

~~simulavr -d attiny85 -f main.elf -g~~

simavr -m attiny85 firmware/main.elf


Install stuff


## Rpi as AVR hobby station (ssh or even gdbgui)
## or docker AVR hobby station with gdbgui.
- compiling locally w crosspack-avr

- simavr for emulator?
- connect to debugging w -x GDB_CMD_FILE (file contains connection stuff to simavr?)

## Reading material

* https://reverseengineering.stackexchange.com/questions/1392/decent-gui-for-gdb
* https://lists.nongnu.org/archive/html/avr-gcc-list/2004-01/msg00213.html
* https://github.com/cyrus-and/gdb-dashboard
* http://www.nongnu.org/avr-libc/
* https://playground.arduino.cc/Code/CmakeBuild
* http://www.ladyada.net/learn/avr
* https://caskroom.github.io/
* file:///usr/local/CrossPack-AVR/manual/documentation.html
* http://fritzing.org/home/
* https://gist.github.com/ryanleary/8250880
* http://www.engbedded.com/fusecalc
* https://en.wikipedia.org/wiki/Atmel_AVR_instruction_set
* http://www.avrbeginners.net/
* https://github.com/buserror/simavr
* https://www.mikrocontroller.net/articles/AVR-Simulation
* https://circuits.io/
* https://github.com/obdev/CrossPack-AVR



# TAKE TWO (all the crap above didn't get me anywhere)

## Setting up the RapberryPi (our development platform)

1) Get an RPI image from https://www.raspberrypi.org/downloads/raspbian/
2) Use etcher to get image on card: https://blog.alexellis.io/getting-started-with-docker-on-raspberry-pi/
3) Enable SSH: before ejecting add a file 'ssh' to the /boot directory.
4) Boot the PI
5) Login ssh: somthing like ssh pi@raspberrypi.local (raspberry)
   - In case you cannot find the RPI check with e.g $ nmap -sn 192.168.178.0/24
6) run sudo raspi-config when needed for boot configuration settings
7) Configure passwordless ssh only: https://www.raspberrypi.org/documentation/remote-access/ssh/passwordless.md
8) apt-get update to update package sources
8) install vim: apt-get install vim
9) Enable wireless: https://www.raspberrypi.org/documentation/configuration/wireless/wireless-cli.md
NOTE, wifi (Edimax EW-7811Un) goes to sleep
$ lsusb # Check usb devices
  ....
  Bus 001 Device 004: ID 7392:7811 Edimax Technology Co., Ltd EW-7811Un 802.11n Wireless Adapter [Realtek RTL8188CUS]
  ...
$ lsmod # Check kernel modules (we will configure this particular module)
  ...
  8192cu                582217  0
  ...
$ sudo vim /etc/modprobe.d/8192cu.conf # Create config file for module. with following content.
```
# Disable power management
options 8192cu rtw_power_mgnt=0 rtw_enusbss=0
```
this will disbale power management, for me this is no problem as the device is mostly plugged to the net.



## FLASHING WITH AVRDUDE (flashing the controller)

* easy
1) Add adafruit package repository to apt
  curl -sLS https://apt.adafruit.com/add | sudo bash
2) sudo apt-get install avrdude

OR

* manually
1) Install dependencies
  $ sudo apt-get update
  $ sudo apt-get install -y build-essential bison flex automake libelf-dev libusb-1.0-0-dev libusb-dev libftdi-dev libftdi1
2) Get and build avrdude
  $ wget http://download.savannah.gnu.org/releases/avrdude/avrdude-6.3.tar.gz
  $ tar xvfz avrdude-6.3.tar.gz
  $ cd avrdude-6.3
  $ ./configure --enable-linuxgpio #check output
  $ make
  $ sudo make install


check if its installed
  $ avrdude -v
3) Connect the pins
```
  ICSP VCC to Raspberry Pi 5 volt pin.
  ICSP GND to Raspberry Pi ground pin.
  ICSP RESET to Raspberry Pi GPIO #12.
  ICSP SCK to Raspberry Pi GPIO #24.
  ICSP MOSI to Raspberry Pi GPIO #23.
  ICSP MISO to Raspberry Pi GPIO #18.
```
[pin layout](https://www.element14.com/community/servlet/JiveServlet/showImage/2-212041-359924/pastedImage_10.png)  

4) Edit config
  $ cp /usr/local/etc/avrdude.conf ~/avrdude_gpio.conf
  $ vim ~/avrdude_gpio.conf

  to end of file add:
```
    # Linux GPIO configuration for avrdude.
    # Change the lines below to the GPIO pins connected to the AVR.
    programmer
      id    = "pi_1";
      desc  = "Use the Linux sysfs interface to bitbang GPIO lines";
      type  = "linuxgpio";
      reset = 12;
      sck   = 24;
      mosi  = 23;
      miso  = 18;
    ;
```

5) Check config
sudo avrdude -p attiny85 -C ~/avrdude_gpio.conf -c pi_1 -v

Troubleshooting
with a basic LED circuit connected to PIN 16 (GPIO 23) you should be able to manually blink it with
$ echo "23" > /sys/class/gpio/export
$ echo "out" > /sys/class/gpio/gpio23/direction
$ echo "1" > /sys/class/gpio/gpio23/value
$ echo "0" > /sys/class/gpio/gpio23/value
$ echo "1" > /sys/class/gpio/gpio23/value
$ echo "0" > /sys/class/gpio/gpio23/value
some pin layout https://www.element14.com/community/thread/58117/l/raspberry-pi-3-gpio-not-working?displayFullThread=true
if its complaining
$ echo "24" > /sys/class/gpio/unexport
6) Flashing (you need to have a pre build file e.g main.hex) (setup in other tutorial)

I uploaded a prebuild hex file from the host $ scp * pi@<your.ip.number.here>:/home/pi/Workspace

$ sudo avrdude -p attiny85 -C ~/avrdude_gpio.conf -c pi_1 -v -U flash:w:main.hex:i



[NEXT BLOG POST hello-avr series/3]
### Building on the Raspberry

I'll just naively start with a new git project in ~/Workspace on the RPI
$ mkdir hello-avr
$ git init

in ./firmware we place two files
main.c containing our source and a Makefile with build instructions
(the Makefile is based on a template from CrossPack-AVR).
In the project root we place a README.md file to put instructions for our future selves.

The project structure should look something like

~.
├── firmware
│   ├── main.c
│   └── Makefile
├── .git
├── .gitignore
└── README.md

and then I'll try to run `make` from the firmware dir...
which won't work... and complains with the errors:
```
avr-gcc -g -Wall -Os -DF_CPU=8000000 -mmcu=attiny85  -c main.c -o main.o
make: avr-gcc: Command not found
Makefile:58: recipe for target 'main.o' failed
make: *** [main.o] Error 127
```

We obviously need to install avr-gcc, unfortunately $ sudo apt-cache search avr-gcc
doesn't find any packages, so I'll just widen the search
$ sudo apt-cache search avr
```
arduino - AVR development board IDE and built-in libraries
avarice - use GDB with Atmel AVR debuggers
avr-evtd - AVR watchdog daemon for Linkstation/Kuroboxes
avr-libc - Standard C library for Atmel AVR development
avra - assembler for Atmel AVR microcontrollers
avrdude - software for programming Atmel AVR microcontrollers
avrdude-doc - documentation for avrdude
avrp - Programmer for Atmel AVR microcontrollers
binutils-avr - Binary utilities supporting Atmel's AVR targets
flashrom - Identify, read, write, erase, and verify BIOS/ROM/flash chips
gcc-avr - GNU C compiler (cross compiler for avr)
gdb-avr - GNU Debugger for avr
golang-github-tendermint-go-wire-dev - Go bindings for the Wire encoding protocol
libavresample-dev - FFmpeg compatibility library for resampling - development files
libavresample3 - FFmpeg compatibility library for resampling - runtime files
libavro-compiler-java - Apache Avro compiler for Java
libavro-java - Apache Avro data serialization system
libavro-maven-plugin-java - Apache Avro Maven plugin
libgringotts-dev - development files for the gringotts data encapsulation library
libgringotts2 - gringotts data encapsulation and encryption library
libopenwalnut1 - Framework for multi-modal medical and brain data visualization
libopenwalnut1-dev - Development files for the OpenWalnut visualization framework
libopenwalnut1-doc - Developer documentation for the OpenWalnut visualization framework
libusbprog-dev - Development files for libusbprog
libusbprog0v5 - Library for programming the USBprog hardware
openwalnut-modules - Loaders, algorithms and visualization modules for OpenWalnut
openwalnut-qt4 - Qt based user interface for OpenWalnut
pacpl - multi-purpose audio converter/ripper/tagger script
python-avro - Apache Avro serialization system — Python 2 library
python-schema-salad - Schema Annotations for Linked Avro Data (SALAD)
python3-avro - Apache Avro serialization system — Python 3 library
r-bioc-savr - GNU R parse and analyze Illumina SAV files
simulavr - Atmel AVR simulator
texlive-latex-extra - TeX Live: LaTeX additional packages
uisp - Micro In-System Programmer for Atmel's AVR MCUs
usbprog - Firmware programming tool for the USBprog hardware
usbprog-gui - GUI firmware programming tool for the USBprog hardware
avrdude-dbgsym - Debug symbols for avrdude
```
Seems we can install gcc-avr then.
$ sudo apt-get install gcc-avr

Lets try the build again... Still failing, because our code depends on [avr-libc](http://www.nongnu.org/avr-libc/)
$ sudo apt-get install avr-libc

Now the build should pass, and we can then upload it with the commands from the previous section.
$ sudo avrdude -p attiny85 -C ~/avrdude_gpio.conf -c pi_1 -v -U flash:w:main.hex:i


The command is a bit long to remember, but we can put most config in the Makefile template.
Replace the programmer line to
```
PROGRAMMER = -C ~/avrdude_gpio.conf -c pi_1
```

and change the flash command to
```
flash:	all
	sudo $(AVRDUDE) -U flash:w:main.hex:i -vvv
```

atm you can only access the ports with sudo.

Update the code to have a faster blinking rate and, build it
$ make
and then flash the chip with
$ make flash

You should see the LED flicker a little during the flashing and then it should start
blinking after flashing has completed. It is probably not recommended to have your own circuit
connected while you're flashing the chip though!

NOTE:
* pushing to github/bitbucket
create a ssh key with `ssh-keygen`
copy the key: `cat ~/.ssh/id_rsa.pub` and add it to your scm provider and follow their
directions for setting up a new repo and pushing your code to it.

[NEXT BLOG POST hello-avr series/4]
### Testing Cloud Editors

* Cloud9 V2
install [nvm](https://github.com/creationix/nvm#install-script)
install node version nvm install lts/boron
install [cloud9 V2](https://github.com/exsilium/cloud9) (testing if it is nice)
can be dockerized https://github.com/exsilium/docker-c9v2/blob/master/Dockerfile
base new Dockerfile on it, install avr stuf like in flashing and building sections

* Eclipse Che/Eclipse Orion
https://www.eclipse.org/che/docs/
https://www.slant.co/versus/1962/2233/~eclipse-che_vs_orion

Che it is! Also needs docker, but environments can be dropped in with dockerfiles
sounds like we want that for our AVR environments we set up erleir on plain Raspberry.
This might not work though, as the image needs to support ARM.

$ curl -sSL https://get.docker.com | sh

then as per instruction add you pi user to docker group

$ sudo usermod -aG docker pi

enable and start the service

$ sudo systemctl enable docker
$ sudo systemctl start docker

https://blog.benjamin-cabe.com/2016/04/01/running-eclipse-che-on-a-raspberry-pi
https://blog.alexellis.io/getting-started-with-docker-on-raspberry-pi/

che needs a jre to be in th path.
$ sudo apt-get install oracle-java8-jdk
and in ~/.profile add
```
export JAVA_HOME=/usr/lib/jvm/jdk-8-oracle-arm32-vfp-hflt
```

run che
$ CHE_IP=192.168.178.69 CHE_PORT=8080 ./bin/che.sh run

Heavy, slow on RPI.

* PlatformIO
Integrates with Atom, so it needs a GUI I'd guess

* Vim
with global setup from github.com/teemuteemu
and screen to switch between terminal and vim. https://stackoverflow.com/questions/70614/gnu-screen-survival-guide
http://www.alexeyshmalko.com/2014/using-vim-as-c-cpp-ide/
https://fishshell.com/




[NEXT BLOG POST hello-avr series/5]
### Debugging AVR

get simavr
get avr-gdb
get guigdb

### PROGRAMMING AVR

* [AVR Tutorials](http://www.avr-tutorials.com/)
