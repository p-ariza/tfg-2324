
# FPGA settings
FPGA_PART = xczu9eg-ffvb1156-2-e
FPGA_TOP = fpga
FPGA_ARCH = zynquplus

# Files for synthesis
SYN_FILES  = rtl/fpga.v
SYN_FILES += rtl/fpga_core.v
SYN_FILES += rtl/eth_xcvr_phy_wrapper.v
SYN_FILES += rtl/eth_xcvr_phy_quad_wrapper.v
SYN_FILES += rtl/debounce_switch.v
SYN_FILES += rtl/sync_signal.v

SYN_FILES += lib/verilog-ethernet/rtl/eth_mac_10g_fifo.v
SYN_FILES += lib/verilog-ethernet/rtl/eth_mac_10g.v
SYN_FILES += lib/verilog-ethernet/rtl/axis_xgmii_rx_64.v
SYN_FILES += lib/verilog-ethernet/rtl/axis_xgmii_tx_64.v
SYN_FILES += lib/verilog-ethernet/rtl/eth_phy_10g.v
SYN_FILES += lib/verilog-ethernet/rtl/eth_phy_10g_rx.v
SYN_FILES += lib/verilog-ethernet/rtl/eth_phy_10g_rx_if.v
SYN_FILES += lib/verilog-ethernet/rtl/eth_phy_10g_rx_frame_sync.v
SYN_FILES += lib/verilog-ethernet/rtl/eth_phy_10g_rx_ber_mon.v
SYN_FILES += lib/verilog-ethernet/rtl/eth_phy_10g_rx_watchdog.v
SYN_FILES += lib/verilog-ethernet/rtl/eth_phy_10g_tx.v
SYN_FILES += lib/verilog-ethernet/rtl/eth_phy_10g_tx_if.v
SYN_FILES += lib/verilog-ethernet/rtl/xgmii_baser_dec_64.v
SYN_FILES += lib/verilog-ethernet/rtl/xgmii_baser_enc_64.v
SYN_FILES += lib/verilog-ethernet/rtl/lfsr.v
SYN_FILES += lib/verilog-ethernet/rtl/eth_axis_rx.v
SYN_FILES += lib/verilog-ethernet/rtl/eth_axis_tx.v
SYN_FILES += lib/verilog-ethernet/rtl/udp_complete_64.v
SYN_FILES += lib/verilog-ethernet/rtl/udp_checksum_gen_64.v
SYN_FILES += lib/verilog-ethernet/rtl/udp_64.v
SYN_FILES += lib/verilog-ethernet/rtl/udp_ip_rx_64.v
SYN_FILES += lib/verilog-ethernet/rtl/udp_ip_tx_64.v
SYN_FILES += lib/verilog-ethernet/rtl/ip_complete_64.v
SYN_FILES += lib/verilog-ethernet/rtl/ip_64.v
SYN_FILES += lib/verilog-ethernet/rtl/ip_eth_rx_64.v
SYN_FILES += lib/verilog-ethernet/rtl/ip_eth_tx_64.v
SYN_FILES += lib/verilog-ethernet/rtl/ip_arb_mux.v
SYN_FILES += lib/verilog-ethernet/rtl/arp.v
SYN_FILES += lib/verilog-ethernet/rtl/arp_cache.v
SYN_FILES += lib/verilog-ethernet/rtl/arp_eth_rx.v
SYN_FILES += lib/verilog-ethernet/rtl/arp_eth_tx.v
SYN_FILES += lib/verilog-ethernet/rtl/eth_arb_mux.v

SYN_FILES += lib/verilog-axis/rtl/arbiter.v
SYN_FILES += lib/verilog-axis/rtl/priority_encoder.v
SYN_FILES += lib/verilog-axis/rtl/axis_fifo.v
SYN_FILES += lib/verilog-axis/rtl/axis_async_fifo.v
SYN_FILES += lib/verilog-axis/rtl/axis_async_fifo_adapter.v
SYN_FILES += lib/verilog-axis/rtl/axis_fifo_adapter.v
SYN_FILES += lib/verilog-axis/rtl/sync_reset.v
SYN_FILES += lib/verilog-axis/rtl/axis_adapter.v
SYN_FILES += lib/verilog-axis/rtl/axis_cobs_encode.v
SYN_FILES += lib/verilog-axis/rtl/axis_cobs_decode.v

SYN_FILES += lib/verilog-axi/rtl/axil_reg_if_rd.v
SYN_FILES += lib/verilog-axi/rtl/axil_reg_if_wr.v
SYN_FILES += lib/verilog-axi/rtl/axil_reg_if.v

SYN_FILES += lib/packetgen/rtl/switch_simple_fifo.v
SYN_FILES += lib/packetgen/rtl/packet_builder.v
SYN_FILES += lib/packetgen/rtl/packetgen.v
SYN_FILES += lib/packetgen/rtl/packetgen_512.v
SYN_FILES += lib/packetgen/rtl/packet_manager.v
SYN_FILES += lib/packetgen/rtl/pm_counter.v
SYN_FILES += lib/packetgen/rtl/conf_iface.v

SYN_FILES += lib/xfcp/rtl/xfcp_interface_uart.v
SYN_FILES += lib/xfcp/rtl/xfcp_mod_axil.v

SYN_FILES += lib/verilog-uart/rtl/uart.v
SYN_FILES += lib/verilog-uart/rtl/uart_rx.v
SYN_FILES += lib/verilog-uart/rtl/uart_tx.v

# XDC files
XDC_FILES = fpga.xdc
XDC_FILES += lib/verilog-ethernet/syn/vivado/eth_mac_fifo.tcl
XDC_FILES += lib/verilog-axis/syn/vivado/axis_async_fifo.tcl
XDC_FILES += lib/verilog-axis/syn/vivado/sync_reset.tcl

# IP
IP_TCL_FILES += ip/eth_xcvr_gt.tcl

include ../common/vivado.mk

program: $(FPGA_TOP).bit
	echo "open_hw" > program.tcl
	echo "connect_hw_server" >> program.tcl
	echo "open_hw_target" >> program.tcl
	echo "current_hw_device [lindex [get_hw_devices] 0]" >> program.tcl
	echo "refresh_hw_device -update_hw_probes false [current_hw_device]" >> program.tcl
	echo "set_property PROGRAM.FILE {$(FPGA_TOP).bit} [current_hw_device]" >> program.tcl
	echo "program_hw_devices [current_hw_device]" >> program.tcl
	echo "exit" >> program.tcl
	vivado -nojournal -nolog -mode batch -source program.tcl

