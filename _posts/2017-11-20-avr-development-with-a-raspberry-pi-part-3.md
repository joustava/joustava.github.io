---
title: AVR development part 3
subtitle: Building AVR firmware with make
tags:
  - avr
  - Raspberry
  - vim
  - cli
  - electronics
  - hello-avr
series: hello-avr
date: 2017-11-20 08:34:08
---

> As I the days start to grow darker again, I was looking around for some interesting things to do with all the electronic 'crap' I have lying around and about in the house, and I came up with writing a series of post covering the setup of a [Raspberry Pi 2](https://en.wikipedia.org/wiki/Raspberry_Pi) to use it as a developing environment for [AVR microcontrollers](https://en.wikipedia.org/wiki/Atmel_AVR).

This is the third post in the 'hello-avr' series. This time I'll describe one way of setting up your Raspberry in order to build the artifacts needed for flashing the device. If you follow along you'll have a complete AVR development environment at your disposal.

**prerequisites**
* You followed the the first two installments
* You are able to flash the controller from the RPI
* Some nano/vim editor experience

### Project structure

I'll just start with a new git project in ~/Workspace on the RPI
``` shell
$ mkdir hello-avr
$ cd hello-avr
$ git init
```
If you are in need of git, you can simply install it with `sudo apt-get install git`. Then in this directory create a subdirectory `./firmware`. In this directory we place two files, **main.c** containing our source and a **Makefile** with build instructions.

The content of the **Makefile** its content is based on a template from [CrossPack for AVR](https://obdev.at/products/crosspack/index.html) with which I dabbled around for a bit before changing to a Raspberry based setup.

```
ENTRYPOINT ?= main
DEVICE     = attiny85
CLOCK      = 8000000
PROGRAMMER = -C ~/avrdude_gpio.conf -c pi_1
OBJECTS    = $(ENTRYPOINT).o
FUSES      = -U lfuse:w:0x62:m -U hfuse:w:0xdf:m -U efuse:w:0xff:m

AVRDUDE = avrdude $(PROGRAMMER) -p $(DEVICE)
COMPILE = avr-gcc -g -Wall -Os -DF_CPU=$(CLOCK) -mmcu=$(DEVICE)

# symbolic targets:
all:	$(ENTRYPOINT).hex

.c.o:
	$(COMPILE) -c $< -o $@

.S.o:
	$(COMPILE) -x assembler-with-cpp -c $< -o $@
# "-x assembler-with-cpp" should not be necessary since this is the default
# file type for the .S (with capital S) extension. However, upper case
# characters are not always preserved on Windows. To ensure WinAVR
# compatibility define the file type manually.

.c.s:
	$(COMPILE) -S $< -o $@

flash:	all  ## Flash the chip with the current build
	sudo $(AVRDUDE) -U flash:w:$(ENTRYPOINT).hex:i -vvv

check:  ## Check if connections are good and chip type is detected.
	sudo $(AVRDUDE) -vv

fuse:
	$(AVRDUDE) $(FUSES)

# if you use a bootloader, change the command below appropriately:
load: all
	bootloadHID $(ENTRYPOINT).hex

clean:  ## Remove all build artifacts
	rm -f $(ENTRYPOINT).hex $(ENTRYPOINT).elf $(OBJECTS)

# file targets:
$(ENTRYPOINT).elf: $(OBJECTS)
	$(COMPILE) -g -o $(ENTRYPOINT).elf $(OBJECTS)

$(ENTRYPOINT).hex: $(ENTRYPOINT).elf
	rm -f $(ENTRYPOINT).hex
	avr-objcopy -j .text -j .data -O ihex $(ENTRYPOINT).elf $(ENTRYPOINT).hex
	avr-size --format=avr --mcu=$(DEVICE) $(ENTRYPOINT).elf
# If you have an EEPROM section, you must also create a hex file for the
# EEPROM and add it to the "flash" target.

# Targets for code debugging and analysis:
disasm:	$(ENTRYPOINT).elf
	avr-objdump -d $(ENTRYPOINT).elf

cpp:
	$(COMPILE) -E $(ENTRYPOINT).c
```

Our source, **main.c** is code that should blink a LED on PB0 (pin 5) of the Attiny85. I wont cover the details in this post.
```
#include <avr/io.h>
#include <util/delay.h>

int main(void)
{
    DDRB = 1 << PB0;
    for(;;){
      char i;
      for(i = 0; i < 10; i++){
        _delay_ms(5);
      }
      PORTB ^= 1 << PB0;
    }
    return 0;
}
```
In the project root we place a **README.md** file, where we can put instructions for our future selves and a **.gitignore** file where we can make git ignore our build files, we dont need to version control those files.

When finished, the project structure should look like
```
hello-avr
├── firmware
│   ├── main.c
│   └── Makefile
├── .git
├── .gitignore
└── README.md
```

and then we'll can try to run `make` from the firmware directory... which won't work... and complains with errors:

```
avr-gcc -g -Wall -Os -DF_CPU=8000000 -mmcu=attiny85  -c main.c -o main.o
make: avr-gcc: Command not found
Makefile:58: recipe for target 'main.o' failed
make: *** [main.o] Error 127
```

We obviously need to install **avr-gcc**, unfortunately a `$ sudo apt-cache search avr-gcc`
doesn't find any packages, so I'll just widen the search with `$ sudo apt-cache search avr`
```
...
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
...
simulavr - Atmel AVR simulator
...
uisp - Micro In-System Programmer for Atmel's AVR MCUs
...
avrdude-dbgsym - Debug symbols for avrdude
```
Seems we can install **avr-gcc** with `sudo apt-get install gcc-avr` instead. Lets try the build again... still failing, because our code depends on [avr-libc](http://www.nongnu.org/avr-libc/) which was also listed in the previous search results, so we can install it with
```
$ sudo apt-get install avr-libc
```
Now, when we run `make`, the build should pass and can be uploaded it with
```
$ sudo avrdude -p attiny85 \
    -C ~/avrdude_gpio.conf \
    -c pi_1 \
    -v \
    -U flash:w:main.hex:i
```

The command is a bit long to remember, but we i have put most config flags in the Makefile template instead. The programmer configuration is the one we covered in the previous post.
```
PROGRAMMER = -C ~/avrdude_gpio.conf -c pi_1
```
in addition to the Attiny85 and Rapberry GPIO Programmer settings, a flash target was added the makefile.
```
flash:	all  ## Flash the chip with the current build
	sudo $(AVRDUDE) -U flash:w:$(ENTRYPOINT).hex:i -vvv
```

Update the code to have a different blinking rate and build it again, this time with
```
$ make
```
and then flash the chip with
```
$ make flash
```

You should see the LED flicker a little during the flashing and then it should start blinking after flashing has completed. It is probably not recommended to have your own circuit connected while you're flashing the chip though, in order to do ISP, you need to have a proper ISP circuit setup.

When done, I recommended you to create a new git repository in e.g Bitbucket or Github. To do this you need to setup an ssh-key on the Raspberry Pi with `ssh-keygen`, then copy the key `cat ~/.ssh/id_rsa.pub` and add it to your scm provider and follow their directions for setting up a new repo and pushing your code to it.


### Sources

* [AVR Toolchain](http://avr-eclipse.sourceforge.net/wiki/index.php/The_AVR_GCC_Toolchain)
* [CrossPack](https://obdev.at/products/crosspack/index.html)
* [avr-libc](http://www.nongnu.org/avr-libc/)
* [Makefile](https://en.wikipedia.org/wiki/Makefile)
* [Vim](http://www.vim.org/)
