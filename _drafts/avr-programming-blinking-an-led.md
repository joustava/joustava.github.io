---
title: 'AVR Programming: Blinking an LED'
#abbrlink: 4c554f17
tags:
---



main.c

```
/* Name: main.c
 * Author: <insert your name here>
 * Copyright: <insert your copyright message here>
 * License: <insert your license reference here>
 */

// http://www.atmel.com/webdoc/avrlibcreferencemanual/group__avr__io.html
#include <avr/io.h>
#include <util/delay.h>

/*
 * This demonstrate how to use the avr_mcu_section.h file
 * The macro adds a section to the ELF file with useful
 * information for the simulator
 */
// #include "../simavr/simavr/sim/avr/avr_mcu_section.h"
// AVR_MCU(F_CPU, "attiny85");

//
// const struct avr_mmcu_vcd_trace_t _mytrace[]  _MMCU_ = {
//    { AVR_MCU_VCD_SYMBOL("DDRB"), .what = (void*)&DDRB, },
//    { AVR_MCU_VCD_SYMBOL("PORTB"), .what = (void*)&PORTB, },
// };

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
       */
      for(i = 0; i < 10; i++){
        _delay_ms(10);
      }

      /*
       * Here is where the blinking magic happens.
       *
       * ^= : Bitwise exclusive OR of Binary Left Shift Operator.
       * << : left value is moved left by the number of bits in right.
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
     * This should never be reached, we return 0 (EXIT_SUCCESS)
     * for good measure as the main return type should be an int.
     */
    return 0;
}
```

### Sources

* [Tiny AVR Programmer Hookup Guide](https://learn.sparkfun.com/tutorials/tiny-avr-programmer-hookup-guide/attiny85-use-hints)
* [Attiny85 external interrupts example](https://github.com/azasypkin/attiny85-external-interrupt)
* [Switch debouncing](http://www.labbookpages.co.uk/electronics/debounce.html)
