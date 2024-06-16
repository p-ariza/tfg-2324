# Makefile

# defaults
SIM ?= icarus
WAVES ?= 1
TOPLEVEL_LANG ?= verilog

DUT			= packetgen_64
TOPLEVEL 	= $(DUT)
MODULE 		= test_$(DUT)

VERILOG_SOURCES += ../../rtl/*
VERILOG_SOURCES += ../../lib/verilog-axis/rtl/axis_fifo_adapter.v
VERILOG_SOURCES += ../../lib/verilog-axis/rtl/axis_fifo.v
VERILOG_SOURCES += ../../lib/verilog-axis/rtl/axis_adapter.v
VERILOG_SOURCES += ../../lib/verilog-axis/rtl/arbiter.v
VERILOG_SOURCES += ../../lib/verilog-axis/rtl/priority_encoder.v
VERILOG_SOURCES += ../../lib/verilog-axi/rtl/axil_reg_if.v
VERILOG_SOURCES += ../../lib/verilog-axi/rtl/axil_reg_if_rd.v
VERILOG_SOURCES += ../../lib/verilog-axi/rtl/axil_reg_if_wr.v

# module parameters

export PARAM_N_FLOWS := 4
export PARAM_SIZES := 44'b00011000000000110000000001100000000011000000
export PARAM_BANDWIDTHS := 128'b00000000000011110100001001000000000000000000111101000010010000000000000000001111010000100100000000000000000011110100001001000000
export PARAM_D_MACS := 192'hABCDEF000001ABCDEF000002ABCDEF000003ABCDEF000004
export PARAM_S_MACS := 192'hBEEFBEEF0001BEEFBEEF0002BEEFBEEF0003BEEFBEEF0004
export PARAM_ETHERTYPES := 64'h0800080008000800
export PARAM_PAYLOADS := 32'hAABBCCDD

# include cocotb's make rules to take care of the simulator setup
include $(shell cocotb-config --makefiles)/Makefile.sim
