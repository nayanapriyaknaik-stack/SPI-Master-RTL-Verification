# FSM-Driven SPI Master Controller & Hardware Verification IP

## Overview

A Verilog-based SPI Master Controller designed using a finite state machine (FSM) and verified using a self-checking simulation testbench.

The project demonstrates RTL design, synchronous digital communication, functional verification, waveform analysis, and simulation automation using open-source tools.

## Features

- 8-bit SPI Master controller
- FSM-driven transaction control
- MSB-first serial data transmission
- Chip Select (CS) control
- Serial Clock (SCLK) generation
- MOSI data transmission
- MISO data sampling
- Asynchronous active-low reset
- Self-checking Verilog testbench
- Multiple SPI transaction verification
- VCD waveform generation for signal-level analysis
- Makefile-based simulation flow

## Project Structure

```text
spi-master-rtl-verification/
├── rtl/
│   └── spi_master.v
├── tb/
│   └── spi_master_tb.v
├── sim/
│   └── Generated simulation files
├── Makefile
├── .gitignore
└── README.md

