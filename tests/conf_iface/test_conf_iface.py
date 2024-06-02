#!/usr/bin/env python

import os, random

import pytest
import cocotb_test.simulator

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import Timer

from cocotbext.axi import AxiLiteMaster, AxiLiteBus

def endian_conversion(hex_str):
    return ''.join([hex_str[i:i+2] for i in range(0, len(hex_str), 2)][::-1])

def rand_hex(length=12):
    return ''.join(random.choice('0123456789ABCDEF') for _ in range(length))

def binstr2hex(x, n):
    return hex(int(x,2))[2:].zfill(n)

@cocotb.test()
async def test_input_fields(dut):
    """
    Input packet fields
    """

    # DUT Parameter
    n_flows = int(os.environ.get("PARAM_N_FLOWS"))


    axil_master = AxiLiteMaster(AxiLiteBus.from_prefix(dut,"s_axil"), dut.clk, dut.rst)

    #Start clock
    cocotb.start_soon(Clock(dut.clk, 3, units="ns").start())

    # Reset DUT
    dut.rst.value = 1
    await Timer(1, units="ns")
    dut.rst.value = 0

    await Timer(1, units="ns")

    for _ in range(1000):
        d_mac      = rand_hex(12)
        s_mac      = rand_hex(12)
        ethertype  = rand_hex(4)
        payload    = rand_hex(2)
        manager_id = random.randint(0,n_flows-1)
        manager_id_hex = hex(manager_id)[2:].zfill(8)
        command = '00000001'
        # Configuration commands
        await axil_master.write(0x0004, bytes.fromhex(d_mac))
        await axil_master.write(0x000C, bytes.fromhex(s_mac))
        await axil_master.write(0x0014, bytes.fromhex(ethertype))
        await axil_master.write(0x0018, bytes.fromhex(payload))
        await axil_master.write(0x001C, bytes.fromhex(manager_id_hex))
        await axil_master.write(0x0000, bytes.fromhex(command))

        # Check output
        assert dut.cfg_en.value == 1
        assert dut.cfg_id.value == manager_id

        assert binstr2hex(dut.cfg_d_mac.value.binstr,     12).upper() == endian_conversion(d_mac).upper()
        assert binstr2hex(dut.cfg_s_mac.value.binstr,     12).upper() == endian_conversion(s_mac).upper()
        assert binstr2hex(dut.cfg_ethertype.value.binstr,  4).upper() == endian_conversion(ethertype).upper()
        assert binstr2hex(dut.cfg_payload.value.binstr,    2).upper() == endian_conversion(payload).upper()
        
        await Timer(random.randint(3,10), units="ns")

# cocotb-test

tests_dir = os.path.dirname(__file__)
rtl_dir = os.path.abspath(os.path.join(tests_dir, '..', '..', 'rtl'))

@pytest.mark.parametrize("n_flows", [1, 4, 16, 64, 256])
def test_packetgen(request, n_flows):

    dut = "conf_iface"
    module = os.path.splitext(os.path.basename(__file__))[0]
    toplevel = dut

    verilog_sources = [
        os.path.join(rtl_dir, f"{dut}.v"),
        os.path.join(rtl_dir, f"axil_reg_if.v"),
        os.path.join(rtl_dir, f"axil_reg_if_wr.v"),
        os.path.join(rtl_dir, f"axil_reg_if_rd.v")
    ]

    parameters = {}
    parameters['N_FLOWS'] = n_flows

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