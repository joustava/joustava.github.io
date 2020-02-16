---
title: AVR development part 2
subtitle: Flashing the Atmel AVR ATtiny85
tags:
  - avr
  - Raspberry
  - electronics
  - hello-avr
series: hello-avr
date: 2017-11-09 21:02:01
---

> As I the days start to grow darker again, I was looking around for some interesting things to do with all the electronic 'crap' I have lying around and about in the house, and I came up with writing a series of post covering the setup of a [Raspberry Pi2](https://en.wikipedia.org/wiki/Raspberry_Pi) to use it as a developing environment for [AVR microcontrollers](https://en.wikipedia.org/wiki/Atmel_AVR).

This is the second post in the 'hello-avr' series, dealing with setting up a basic AVR toolset on a Raspberry Pi. When finished the Raspberry Pi can act as an ISP and you will have the ability to flash the controller with a build artefact from the command line interface.

**prerequisites**
* You followed the the first instalment - link - and can ssh into the Pi.
* Breadboard to put the controller on
* Wires/leads to make connections between RPI GPIO and controller pins

### Installing avrdude

In order to flash the controller we need a tool called **avrdude**. When avrdude is configured correctly we can easily flash the micro controller from the command line through the ISP circuit.

There are a couple of way to install avrdude. One is via Adafruit

1. Add adafruit package repository to apt
``` bash
$ curl -sLS https://apt.adafruit.com/add | sudo bash
```
2. Then install the package
``` bash
$ sudo apt-get install avrdude
```

Or use the second option. This will take little longer and requires you to build manually from source.

1. Install dependencies for building **avrdude**
``` bash
$ sudo apt-get update
$ sudo apt-get install -y \
  build-essential \
  bison \
  flex \
  automake \
  libelf-dev \
  libusb-1.0-0-dev \
  libusb-dev \
  libftdi-dev \
  libftdi1
```
2. Get and build avrdude

``` bash
$ wget http://download.savannah.gnu.org/releases/avrdude/avrdude-6.3.tar.gz
$ tar xvfz avrdude-6.3.tar.gz
$ cd avrdude-6.3
$ ./configure --enable-linuxgpio
$ make
$ sudo make install
```
This might take some time, be patient, enjoy some beverage, read a book. Either way, once everything is done **avrdude** should be available from the command line.

``` bash
$ avrdude -v

avrdude: Version 6.3
         Copyright (c) 2000-2005 Brian Dean, http://www.bdmicro.com/
         Copyright (c) 2007-2014 Joerg Wunsch

         System wide configuration file is "/etc/avrdude.conf"
         User configuration file is "/home/pi/.avrduderc"
         User configuration file does not exist or is not a regular file, skipping


avrdude: no programmer has been specified on the command line or the config file
         Specify a programmer using the -c option and try again

```

Lets continue with making some connections.

### The ISP circuit

With **avrdude** alone we cannot really do anything special. We need to create an ISP circuit to connect the Raspberry Pi's GPIOs with the microcontroller. The circuit here is tested with an attiny85 microcontroller but it should support a wider range of this type of controllers.

Place the microcontroller on a breadboard and route wires from the RPI GPIO header to the Attiny85 pins according to this table

| t85 | Pi |
| :---: | :---: |
| VCC  | 5V (pin 2, 4)|
| GND  | GND pin 6,9,14,20,25,30,34,39|
| RESET | GPIO 12 (pin 32)|
| SCK | GPIO 24 (pin 18)|
| MOSI | GPIO 23 (pin 16)|
| MISO | GPIO 18 (pin 12)|


Note that the GPIO numbering is **NOT** the physical pin numbering. Have a look at this excellent [Raspberry GPIO reference](https://pinout.xyz/). For the controller you can refer to the following Attiny85 pin schematics.

```
# Attiny85 Pins

1 - * - 8
2 -   - 7
3 -   - 6
4 -   - 5
```

| Pin n | modes | name |
| :---: | :---: | :---: |
| Pin 1 | PCINT5/RESET/ADC0/dW | PB5 |
| Pin 2 | PCINT3/XTAL1/CLKI/OC1B/ADC3 | PB3 |
| Pin 3 | PCINT4/XTAL2/CLKO/OC1B/ADC2 | PB4 |
| Pin 4 | \- | GND |
| Pin 5 | MOSI/DI/SDA/AIN0/OC0A/OC1A/AREF/PCINT0) | PB0 |
| Pin 6 | MISO/DO/AIN1/OC0B/OC1A/PCINT1) | PB1 |
| Pin 7 | SCK/USCK/SCL/ADC1/T0/INT0/PCINT2) | PB2 |
| Pin 8 | \- | VCC |

Please check carefully if everything is connected as described. Then lets get busy with configuring avrdude.

### Avrdude configuration

To make avrdude aware about us wanting to use the Raspberry as the ISP, we need to add some configuration.

1. Copy an example configuration and open it
```
  $ cp /usr/local/etc/avrdude.conf ~/avrdude_gpio.conf
  $ vim ~/avrdude_gpio.conf
```
2. to end of file add
```
# RPI GPIO configuration for avrdude.
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
This make avrdude aware of a new programmer that uses linuxgpio to talk to the configured pins. If you have deviated from the pin numbers in previous sections, you need to also update the pin assignments accordingly. When done, save! Now we can check if our config works

``` bash
$ sudo avrdude -p attiny85 -C ~/avrdude_gpio.conf -c pi_1

avrdude: AVR device initialized and ready to accept instructions

Reading | ################################################## | 100% 0.00s

avrdude: Device signature = 0x1e930b (probably t85)

avrdude: safemode: Fuses OK (E:FF, H:DF, L:62)

avrdude done.  Thank you.
```

You should get an output similar to the above. If not, you can try again with `-v` flag added to the end to the command, to get a more detailed output for troubleshooting. Only continue with the
next section when you have finished the current one successfully.

### Flashing the chip

Finally, you are ready to flash the controller with some code. We have not covered how to build artifacts which we can flash to the controller, I'll cover that in the next post. For now, you can [download a hex file](https://gist.githubusercontent.com/joustava/d38c96087054eafdaa2d07bbd03f86bf/raw/ded8329e66754b91556c4558204afa7ef02364a5/main.hex) I build before onto the Pi with eg curl.

```
$ curl <url> -o main.hex
```

This is a build of a simple c program that will blink a LED connected to PBO (Pin 5) of the Attiny85.

```
/* Name: main.c
 * Author: <insert your name here>
 * Copyright: <insert your copyright message here>
 * License: <insert your license reference here>
 */

// http://www.atmel.com/webdoc/avrlibcreferencemanual/group__avr__io.html
#include <avr/io.h>
#include <util/delay.h>

int main(void)
{
    /*
     *  initialization
     *
     * DDRB is the "data direction register" for port B,
     * the ATtinyX5 only has port B with usable pins.
     *
     * Here we only configure PB0 (pin 5) as an output
     *
     * Example:
     *
     *  PBO 0000 0001
     *    1 0000 0001
     * -------------- <<
     * DDRB 0000 0010
     */

    DDRB = 1 << PB0;


    for(;;){

      /*
      * main program loop.
      */

      char i;

      /*
       * Here we use a predefined _delay function
       * to delay the following operation to execute.
       * i.e we wait a while.
       *
       */
      for(i = 0; i < 10; i++){
        _delay_ms(10);
      }

      /*
       * Here is where the blinking magic happens.
       *
       * ^= : Bitwise exclusive OR of Binary Left Shift Operator.
       * << : left op. value is moved left by the number of bits specified by right op.
       *
       * Example:
       *
       *   PBO  0000 0001
       *     1  0000 0001
       * --------------------------- <<
       *        0000 0010
       * PORTB  0000 0000
       * --------------------------- ^=
       * PORTB  0000 0010
       */
      PORTB ^= 1 << PB0;
    }

    /*
     * This should never be reached.
     * we return 0 (EXIT_SUCCESS) for good measure
     * as the main return type should be an int.
     */
    return 0;
}
```
Please excuse me if some of the comments are incorrect, I'm not a professional C/AVR programmer, I'm open to feedback for better explanations.

Now, from the directory where you downloaded the `main.hex` to, execute the following to finally flash the controller.
```
$ sudo avrdude -p attiny85 -C ~/avrdude_gpio.conf -c pi_1 -U flash:w:main.hex:i

avrdude: AVR device initialized and ready to accept instructions

Reading | ################################################## | 100% 0.00s

avrdude: Device signature = 0x1e930b (probably t85)
avrdude: NOTE: "flash" memory has been specified, an erase cycle will be performed
         To disable this feature, specify the -D option.
avrdude: erasing chip
avrdude: reading input file "main.hex"
avrdude: writing flash (126 bytes):

Writing | ################################################## | 100% 0.07s

avrdude: 126 bytes of flash written
avrdude: verifying flash memory against main.hex:
avrdude: load data flash data from input file main.hex:
avrdude: input file main.hex contains 126 bytes
avrdude: reading on-chip flash data:

Reading | ################################################## | 100% 0.06s

avrdude: verifying ...
avrdude: 126 bytes of flash verified

avrdude: safemode: Fuses OK (E:FF, H:DF, L:62)

avrdude done.  Thank you.
```
This is the output when the flashing went smooth. If you get errors, again just add `-v` to the command to have a more verbose output.

Now that our Pi is setup to flash we are ready to start developing. In the next post I'll cover one way of setting up your development environment in order to have a relatively smooth workflow.

### Troubleshooting

Debugging RPI GPIO:

With a basic LED circuit connected to PIN 16 (GPIO 23) you should be able to manually blink it with
``` bash
$ echo "23" > /sys/class/gpio/export
$ echo "out" > /sys/class/gpio/gpio23/direction
$ echo "1" > /sys/class/gpio/gpio23/value
$ echo "0" > /sys/class/gpio/gpio23/value
$ echo "1" > /sys/class/gpio/gpio23/value
$ echo "0" > /sys/class/gpio/gpio23/value
```
if not, you might have to unexport the GPIO first.
```
$ echo "24" > /sys/class/gpio/unexport
```

### Sources

* [Avrdude releases](http://download.savannah.gnu.org/releases/avrdude/)
* [RPI GPIO schematic](https://www.element14.com/community/servlet/JiveServlet/showImage/2-212041-359924/pastedImage_10.png)
* [Pinout](https://pinout.xyz/)
* [AVR Libc reference](http://www.atmel.com/webdoc/avrlibcreferencemanual/index.html)
* [AVR C Runtime Library](http://www.nongnu.org/avr-libc/)
* [ISP Application notes](http://www.atmel.com/Images/Atmel-0943-In-System-Programming_ApplicationNote_AVR910.pdf)
* [Programming Arduino with RPI](https://learn.adafruit.com/program-an-avr-or-arduino-using-raspberry-pi-gpio-pins/overview)
