#!/usr/bin/env python

import os
import re

import pytest
import cocotb_test.simulator

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import Timer

from cocotbext.axi import AxiStreamBus, AxiStreamSink, AxiStreamFrame

def split_int_parameter(parameter, value_size, n_flows):
    full_parameter = re.search(r"[bh]([0-9a-fA-F]+)", os.environ.get(parameter)).group(1)
    values = [None] * n_flows
    for f in range(n_flows):
        values[f] = int(full_parameter[f*value_size:(f+1)*value_size], 2)
    return values

def split_string_parameter(parameter, value_size, n_flows):
    full_parameter = re.search(r"[bh]([0-9a-fA-F]+)", os.environ.get(parameter)).group(1)
    values = [None] * n_flows
    for f in range(n_flows):
        values[f] = full_parameter[f*value_size:(f+1)*value_size]
    return values

@cocotb.test()
async def run_frame_content_test(dut):
    """
    Checking frame contents
    """
    #DUT Parameters
    n_flows = int(os.environ.get("PARAM_N_FLOWS"))
   
    sizes = split_int_parameter("PARAM_SIZES",11,n_flows)
    bandwidths = split_int_parameter("PARAM_BANDWIDTHS",32,n_flows)
    d_macs = split_string_parameter("PARAM_D_MACS",12,n_flows)
    s_macs = split_string_parameter("PARAM_S_MACS",12,n_flows)
    ethertypes = split_string_parameter("PARAM_ETHERTYPES",4,n_flows)
    payloads = split_string_parameter("PARAM_PAYLOADS",2,n_flows)

    # Create frames
    axi_frames = [None] * n_flows
    for f in range(n_flows):
        axi_frames[f] = AxiStreamFrame(bytearray.fromhex(d_macs[f] + s_macs[f] + ethertypes[f] + payloads[f]*(sizes[f]-14)), [1]*sizes[f]).tdata

    #AxiStream Sink
    axis_sink = AxiStreamSink(AxiStreamBus.from_prefix(dut, "axis"), dut.clk, dut.rst)
    
    #Start clock
    cocotb.start_soon(Clock(dut.clk, 3, units="ns").start())

    # Reset DUT
    dut.rst.value = 1
    await Timer(1, units="ns")
    dut.rst.value = 0

    # Check 1000 frames' content
    for _ in range(1000):
        recv_frame = await axis_sink.recv(compact=True)
        recv_frame.tid = recv_frame.tdest = recv_frame.tuser = recv_frame.sim_time_start = recv_frame.sim_time_end = None
        assert recv_frame.tdata in axi_frames

@cocotb.test()
async def run_bandwidth_test(dut):
    """
    Testing bandwidth generated by the DUT
    """

    #DUT Parameters
    frequency = dut.FREQUENCY.value
    n_flows = int(os.environ.get("PARAM_N_FLOWS"))

    sizes = split_int_parameter("PARAM_SIZES",11,n_flows)
    bandwidths = split_int_parameter("PARAM_BANDWIDTHS",32,n_flows)
    d_macs = split_string_parameter("PARAM_D_MACS",12,n_flows)
    s_macs = split_string_parameter("PARAM_S_MACS",12,n_flows)
    ethertypes = split_string_parameter("PARAM_ETHERTYPES",4,n_flows)
    payloads = split_string_parameter("PARAM_PAYLOADS",2,n_flows)


    # Create frames
    axi_frames = [None] * n_flows
    for f in range(n_flows):
        axi_frames[f] = AxiStreamFrame(bytearray.fromhex(d_macs[f] + s_macs[f] + ethertypes[f] + payloads[f]*(sizes[f]-14)), [1]*sizes[f])

    period = round(1/(frequency/pow(10,9)),3)

    dut._log.info("Clock period: %f", period)

    #AxiStream Sink
    axis_sink = AxiStreamSink(AxiStreamBus.from_prefix(dut, "axis"), dut.clk, dut.rst)

    #Start clock
    cocotb.start_soon(Clock(dut.clk, period, units="ns").start())

    # Reset DUT
    dut.rst.value = 1
    await Timer(1, units="ns")
    dut.rst.value = 0

    byte_counts = [0] * n_flows
    start_ns = cocotb.utils.get_sim_time(units="ns")
    for _ in range(100000):
        recv_frame = await axis_sink.recv()
        for i, frame in enumerate(axi_frames):
            if(recv_frame == frame):
                byte_counts[i] += len(recv_frame.tdata)

    end_ns = cocotb.utils.get_sim_time(units="ns")

    for count in byte_counts:
        count = count

    elapsed_time_ns = end_ns - start_ns
    dut._log.info("Elapsed time: %d - %d = %d", end_ns, start_ns, elapsed_time_ns)
    # Output bandwidths in bits/s
    out_bws = [(count*8/elapsed_time_ns)*pow(10,9) for count in byte_counts]

    error_range = 0.001
    for flow, bw in enumerate(out_bws):
        assert bandwidths[flow]*(1-error_range) < bw
        assert bandwidths[flow]*(1+error_range) > bw

# cocotb-test

tests_dir = os.path.dirname(__file__)
rtl_dir = os.path.abspath(os.path.join(tests_dir, '..', '..', 'rtl'))



@pytest.mark.parametrize(("n_flows", "bandwidths", "sizes", "d_macs", "s_macs", "ethertypes", "payloads"), 
        [
        (1, (pow(10,9),), (64,),
          ("ABCDEF000001",),
          ("BEEFBEEF0001",),
          ("0800",), ("AA",)
        ),
        (1, (pow(10,9),), (1522,),
          ("ABCDEF000001",),
          ("BEEFBEEF0001",),
          ("0800",), ("AA",)
        ),
        (1, (10*pow(10,9),), (64,),
          ("ABCDEF000001",),
          ("BEEFBEEF0001",),
          ("0800",), ("AA",)
        ),
        (1, (10*pow(10,9),), (1522,),
          ("ABCDEF000001",),
          ("BEEFBEEF0001",),
          ("0800",), ("AA",)
        ),
        (4, (pow(10,9), 2*pow(10,9), 3*pow(10,9), 4*pow(10,9)), (64,128,256,512),
          ("ABCDEF000001", "ABCDEF000002", "ABCDEF000001", "ABCDEF000004"),
          ("BEEFBEEF0001", "BEEFBEEF0002", "BEEFBEEF0001", "BEEFBEEF0004"),
          ("0800",)*4, ("AA", "BB", "CC", "DD")
        ),
        (5, (pow(10,9),)*5, tuple(2**i for i in range(6,11)),
          ("ABCDEF000001",)*5,
          ("BEEFBEEF0001",)*5,
          ("0800",)* 5, tuple(format(i, '02x') for i in range(6,11))
        ),
        (15, (2*pow(10,9),)*15, tuple(100*i for i in range(1,16)),
          ("ABCDEF000001",)*15,
          ("BEEFBEEF0001",)*15,
          ("0800",)* 15, tuple(format(i, '02x') for i in range(1,16))
        ),
        (100, (pow(10,9),)*100, (64,)*100,
          ("ABCDEF000001",)*100,
          ("BEEFBEEF0001",)*100,
          ("0800",)* 100, tuple(format(i, '02x') for i in range(1,101))
        ),
        (100, (pow(10,9),)*100, (300,)*100,
          ("ABCDEF000001",)*100,
          ("BEEFBEEF0001",)*100,
          ("0800",)* 100, tuple(format(i, '02x') for i in range(1,101))
        )
        ]
    )
def test_packetgen(request, n_flows, bandwidths, sizes, d_macs, s_macs, ethertypes, payloads):

    dut = "packetgen"
    module = os.path.splitext(os.path.basename(__file__))[0]
    toplevel = dut

    verilog_sources = [
        os.path.join(rtl_dir, f"{dut}.v"),
        os.path.join(rtl_dir, f"arbiter.v"),
        os.path.join(rtl_dir, f"packet_builder.v"),
        os.path.join(rtl_dir, f"packet_manager.v"),
        os.path.join(rtl_dir, f"switch_simple_fifo.v"),
        os.path.join(rtl_dir, f"pm_counter.v"),
        os.path.join(rtl_dir, f"priority_encoder.v"),
        os.path.join(rtl_dir, f"conf_iface.v"),
        os.path.join(rtl_dir, f"axil_reg_if.v"),
        os.path.join(rtl_dir, f"axil_reg_if_wr.v"),
        os.path.join(rtl_dir, f"axil_reg_if_rd.v")
    ]

    parameters = {}
    parameters['N_FLOWS'] = n_flows

    #Required conversion from decimal to binary
    binary_sizes = [bin(size)[2:].zfill(11) for size in sizes]
    binary_bandwidths = [bin(bw)[2:].zfill(32) for bw in bandwidths]

    parameters['SIZES']         = str(n_flows*11)+"'b"+"".join(binary_sizes)
    parameters['BANDWIDTHS']    = str(n_flows*32)+"'b"+"".join(binary_bandwidths)

    parameters['D_MACS']        = str(n_flows*48 )+"'h"+"".join(d_macs)
    parameters['S_MACS']        = str(n_flows*48 )+"'h"+"".join(s_macs)
    parameters['ETHERTYPES']    = str(n_flows*16 )+"'h"+"".join(ethertypes)
    parameters['PAYLOADS']      = str(n_flows*8 )+"'h"+"".join(payloads)
    

    extra_env = {f'PARAM_{k}': str(v) for k, v in parameters.items()}

    sim_build = os.path.join(tests_dir, "sim_build",
        request.node.name.replace('[', '-').replace(']', ''))

    cocotb_test.simulator.run(
        python_search=[tests_dir],
        verilog_sources=verilog_sources,
        toplevel=toplevel,
        module=module,
        parameters=parameters,
        sim_build=sim_build,
        extra_env=extra_env,
    )