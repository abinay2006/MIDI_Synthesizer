# MIDI_Synthesizer

This project implements a MIDI synthesizer on an FPGA that receives serial MIDI note messages and produces the corresponding audio through a speaker. The RTL diagram is given below <img width="1362" height="457" alt="Screenshot 2026-10-18 at 3 37 09 PM" src="https://github.com/user-attachments/assets/cde66903-27f6-4963-b2fc-3b3bb553c854" />

The VHDL code and testbench is generated for each of the following components:

1. Clock Divider
This component takes as an input the FPGA’s 100 MHz clock and outputs a system clock at 25 MHz. The component also forwards this clock to the D2A converter, using the SPI communication protocol, meeting the D2A converter’s maximum SPI clock speed of 30 MHz.

2. Input Synchronizer
The input goes through a double flip-flop synchronizer. By delaying each keyboard input by two clock cycles, this component prevents metastability
   
3. SCI Receiver
This component receives all incoming MIDI data, using a finite state machine (FSM) format to load and shift each bit of data. Since the MIDI protocol uses the first byte to indicate note on/off and the second byte to specify which note was played, the SCI receiver outputs only the second byte to the DDS generator.

4. DDS Generator
The DDS generator receives MIDI data from the SCI receiver and produces a sinusoidal output that allows a speaker to play a sound at the specified frequency. This process calculates a phase angle increase that modifies a base frequency sine wave.

5. SPI Transmitter
The SPI Transmitter communicates the sinusoidal output to the digital-to-analog converter. This procedure, which utilizes a chip select (CS) and sends MSB-first serial data, is specified by the user manual for the D2A converter.

