# MIDIDance

Interface between a number of [Arduino](http://arduino.cc/) boards via USB and a MIDI-capable software like a synthesizer, [Ableton Live](https://www.ableton.com/) etc.

Written in [Processing](http://processing.org/). Also includes scripts to program the Arduino hardware.

Detects sudden movements on any one axis and converts it to a specified MIDI tone. Any given set of axis can be assigned also to MIDI controllers, transmitting rescaled values without beat detection.

See comments in source code for details. All global parameters of the program can be found in the main file `MIDIDance.pde`.


### Features

It comes with two types of event detectors:

- A _linear_ one, which assigns the outcome based on the axis which had the maximum slope.
- A _Bayesian_ analyzer, which builds a simple model based on the average trajectory of a number of recorded events (can be assigned to their target outcomes on-line).

Also, any number of axis can be assigned to be _controllers_, i. e. signals where no event detection is being performed, which are just rescaled to standard MIDI range and transmitted to a specified MIDI port.
