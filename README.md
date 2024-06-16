# Verilog Network Traffic Generator Readme

## Introduction

Verilog based MAC frame generator based on AXI Stream bus. The output is parametrizable in interface width. Includes `cocotb` testbenches utilizing [cocotbext-axi](https://github.com/alexforencich/cocotbext-axi).

Many thanks to Alex Forencich for his work on [verilog-axi](https://github.com/alexforencich/verilog-axi), [verilog-axis](https://github.com/alexforencich/verilog-axis), [verilog-ethernet](https://github.com/alexforencich/verilog-ethernet) and [xfcp](https://github.com/alexforencich/xfcp). This repository is based on Alex's work on AXI components and examples.

It also includes `cocotb` testbenches utilizing [cocotbext-axi](https://github.com/alexforencich/cocotbext-axi).

This repository has been developed for my final project for UGR's Computer Engineering Degree.

## Documentation

### `packetgen.v` module

Traffic generator module with parametrizable output interface width. Generated traffic flows are statically defined via parameters. It also offers a 32 bit configuration interface which supports changing the MAC frames fields. Wrapper for `packetgen_512`.

### `packetgen_512.v` module

Traffic generator module with fixed 512 bit output interface width. Generated traffic flows are statically defined via parameters. It also offers a 32 bit configuration interface which supports changing the MAC frames fields.

### `packet_builder.v` module

MAC frame builder module. Fixed 512 bit width AXI Stream interface.

### `packet_manager.v` module

Packet "command" generator module. Represents a single traffic flow and generates commands according to it's parameters.

### `pm_counter.v` module

Counter with changing length to offer an average time between pulses that isn't a multiple of clock period.

### `conf_iface.v` module

AXI Lite configuration interface. Width of 32 bits. Supports changing MAC frame headers.

### `switch_simple_fifo.v` module

Modified version of Alex Forencich's AXI4-Stream FIFO.

---
## Future work
It's planned to add complete in real time configuration, allowing to change each flow desired bandwidth and size of frames.