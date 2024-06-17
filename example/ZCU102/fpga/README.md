# Verilog Traffic Generator ZCU102 Example Design

## Introduction

This example design targets the Xilinx ZCU102 FPGA board.

The design by default listens to UDP port 1234 at IP address 192.168.1.128 and
will echo back any packets received.  The design will also respond correctly
to ARP requests.  

*  FPGA: xczu9eg-ffvb1156-2-e
*  PHY: 10G BASE-R PHY IP core and internal GTY transceiver

## How to build

Run make to build.  Ensure that the Xilinx Vivado toolchain components are
in PATH.