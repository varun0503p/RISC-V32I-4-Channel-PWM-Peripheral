# RISC-V32I 4-Channel PWM Peripheral

## Overview
This project implements a custom 4-channel PWM (Pulse Width Modulation) peripheral compatible with the RISC-V32I architecture. The peripheral is designed to generate four independent PWM signals with configurable duty cycles and frequency settings for embedded and FPGA-based applications.

The project is implemented using Verilog HDL and tested on the Boolean XC7S50 FPGA board.

---

## Features
- 4 independent PWM output channels
- Configurable duty cycle for each channel
- Adjustable PWM frequency
- RISC-V32I compatible peripheral interface
- FPGA implementation and testing support
- Modular and scalable design

---

## Hardware Requirements
- Boolean XC7S50 FPGA Board
- USB Programmer / JTAG Interface
- Power Supply
- LEDs / Oscilloscope for PWM verification

---

## Software Requirements
- Vivado Design Suite
- Verilog HDL
- RISC-V Toolchain (if processor integration is used)

---


---

## Working Principle
The peripheral generates PWM signals by comparing a counter value with programmed duty cycle values. Each channel operates independently, enabling simultaneous control of multiple outputs.

PWM Duty Cycle Formula:

Duty Cycle (%) = (ON Time / Total Period) × 100

---

## Implementation Steps
1. Design PWM architecture in Verilog
2. Create individual PWM channels
3. Integrate channels into a peripheral interface
4. Simulate functionality using testbench
5. Synthesize and implement using Vivado
6. Program the Boolean XC7S50 board
7. Verify PWM outputs using LEDs or oscilloscope

---

## Applications
- Motor Speed Control
- LED Brightness Control
- Servo Control
- Embedded Systems
- Robotics Applications

---

## Future Improvements
- Add interrupt support
- AXI/APB bus compatibility
- Higher resolution PWM
- Dynamic frequency scaling

---



