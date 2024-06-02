# Makefile

# defaults
SIM ?= icarus
WAVES ?= 1
TOPLEVEL_LANG ?= verilog

DUT			= conf_iface
TOPLEVEL 	= $(DUT)
MODULE 		= test_$(DUT)

VERILOG_SOURCES += ../../rtl/*

# module parameters

export PARAM_N_FLOWS := 4

# include cocotb's make rules to take care of the simulator setup
include $(shell cocotb-config --makefiles)/Makefile.sim
