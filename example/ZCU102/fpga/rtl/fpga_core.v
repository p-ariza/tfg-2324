/*

Copyright (c) 2020-2021 Alex Forencich

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

*/
/*
 * Example based on Alex Forencich ZCU102 example on verilog-ethernet
 */

// Language: Verilog 2001

`resetall
`timescale 1ns / 1ps
`default_nettype none

/*
 * FPGA core logic
 */
module fpga_core
(
    /*
     * Clock: 156.25MHz
     * Synchronous reset
     */
    input  wire        clk,
    input  wire        rst,

    /*
     * GPIO
     */
    input  wire        btnu,
    input  wire        btnl,
    input  wire        btnd,
    input  wire        btnr,
    input  wire        btnc,
    input  wire [7:0]  sw,
    output wire [7:0]  led,

    /*
     * UART: 115200 bps, 8N1
     */
    input  wire        uart_rxd,
    output wire        uart_txd,
    input  wire        uart_rts,
    output wire        uart_cts,

    /*
     * Ethernet: SFP+
     */
    input  wire        sfp0_tx_clk,
    input  wire        sfp0_tx_rst,
    output wire [63:0] sfp0_txd,
    output wire [7:0]  sfp0_txc,
    input  wire        sfp0_rx_clk,
    input  wire        sfp0_rx_rst,
    input  wire [63:0] sfp0_rxd,
    input  wire [7:0]  sfp0_rxc,
    input  wire        sfp1_tx_clk,
    input  wire        sfp1_tx_rst,
    output wire [63:0] sfp1_txd,
    output wire [7:0]  sfp1_txc,
    input  wire        sfp1_rx_clk,
    input  wire        sfp1_rx_rst,
    input  wire [63:0] sfp1_rxd,
    input  wire [7:0]  sfp1_rxc,
    input  wire        sfp2_tx_clk,
    input  wire        sfp2_tx_rst,
    output wire [63:0] sfp2_txd,
    output wire [7:0]  sfp2_txc,
    input  wire        sfp2_rx_clk,
    input  wire        sfp2_rx_rst,
    input  wire [63:0] sfp2_rxd,
    input  wire [7:0]  sfp2_rxc,
    input  wire        sfp3_tx_clk,
    input  wire        sfp3_tx_rst,
    output wire [63:0] sfp3_txd,
    output wire [7:0]  sfp3_txc,
    input  wire        sfp3_rx_clk,
    input  wire        sfp3_rx_rst,
    input  wire [63:0] sfp3_rxd,
    input  wire [7:0]  sfp3_rxc
);

// XFCP UART interface
wire [7:0] xfcp_uart_interface_down_tdata;
wire xfcp_uart_interface_down_tvalid;
wire xfcp_uart_interface_down_tready;
wire xfcp_uart_interface_down_tlast;
wire xfcp_uart_interface_down_tuser;

wire [7:0] xfcp_uart_interface_up_tdata;
wire xfcp_uart_interface_up_tvalid;
wire xfcp_uart_interface_up_tready;
wire xfcp_uart_interface_up_tlast;
wire xfcp_uart_interface_up_tuser;

assign uart_cts = 1'b1;

xfcp_interface_uart
xfcp_interface_uart_inst (
    .clk(clk),
    .rst(rst),
    .uart_rxd(uart_rxd),
    .uart_txd(uart_txd),
    .down_xfcp_in_tdata(xfcp_uart_interface_up_tdata),
    .down_xfcp_in_tvalid(xfcp_uart_interface_up_tvalid),
    .down_xfcp_in_tready(xfcp_uart_interface_up_tready),
    .down_xfcp_in_tlast(xfcp_uart_interface_up_tlast),
    .down_xfcp_in_tuser(xfcp_uart_interface_up_tuser),
    .down_xfcp_out_tdata(xfcp_uart_interface_down_tdata),
    .down_xfcp_out_tvalid(xfcp_uart_interface_down_tvalid),
    .down_xfcp_out_tready(xfcp_uart_interface_down_tready),
    .down_xfcp_out_tlast(xfcp_uart_interface_down_tlast),
    .down_xfcp_out_tuser(xfcp_uart_interface_down_tuser),
    .prescale(156250000/(115200*8))
);

// AXI lite connections
parameter AXIL_CTRL_ADDR_WIDTH = AXIL_ADDR_WIDTH-4;   
parameter AXIL_CTRL_BASE_ADDR = 0;

parameter AXIL_DATA_WIDTH = 32;
parameter AXIL_ADDR_WIDTH = 32;

// AXIL master coming from XFCP
wire [AXIL_ADDR_WIDTH-1:0] axil_xfcp_awaddr;
wire [2:0]                 axil_xfcp_awprot;
wire                       axil_xfcp_awvalid;
wire                       axil_xfcp_awready;
wire [AXIL_DATA_WIDTH-1:0] axil_xfcp_wdata;
wire [4-1:0]               axil_xfcp_wstrb;
wire                       axil_xfcp_wvalid;
wire                       axil_xfcp_wready;
wire [1:0]                 axil_xfcp_bresp;
wire                       axil_xfcp_bvalid;
wire                       axil_xfcp_bready;
wire [AXIL_ADDR_WIDTH-1:0] axil_xfcp_araddr;
wire [2:0]                 axil_xfcp_arprot;
wire                       axil_xfcp_arvalid;
wire                       axil_xfcp_arready;
wire [AXIL_DATA_WIDTH-1:0] axil_xfcp_rdata;
wire [1:0]                 axil_xfcp_rresp;
wire                       axil_xfcp_rvalid;
wire                       axil_xfcp_rready;

// AXIL master for control
xfcp_mod_axil #(
    .XFCP_ID_STR("XFCP AXIL Master"),
    .COUNT_SIZE(16),
    .DATA_WIDTH(AXIL_DATA_WIDTH),
    .ADDR_WIDTH(AXIL_ADDR_WIDTH),
    .STRB_WIDTH(4)
)
xfcp_mod_axil_inst (
    .clk(clk),
    .rst(rst),
    .up_xfcp_in_tdata(xfcp_uart_interface_down_tdata),
    .up_xfcp_in_tvalid(xfcp_uart_interface_down_tvalid),
    .up_xfcp_in_tready(xfcp_uart_interface_down_tready),
    .up_xfcp_in_tlast(xfcp_uart_interface_down_tlast),
    .up_xfcp_in_tuser(xfcp_uart_interface_down_tuser),
    .up_xfcp_out_tdata(xfcp_uart_interface_up_tdata),
    .up_xfcp_out_tvalid(xfcp_uart_interface_up_tvalid),
    .up_xfcp_out_tready(xfcp_uart_interface_up_tready),
    .up_xfcp_out_tlast(xfcp_uart_interface_up_tlast),
    .up_xfcp_out_tuser(xfcp_uart_interface_up_tuser),
    .m_axil_awaddr(axil_xfcp_awaddr),
    .m_axil_awprot(axil_xfcp_awprot),
    .m_axil_awvalid(axil_xfcp_awvalid),
    .m_axil_awready(axil_xfcp_awready),
    .m_axil_wdata(axil_xfcp_wdata),
    .m_axil_wstrb(axil_xfcp_wstrb),
    .m_axil_wvalid(axil_xfcp_wvalid),
    .m_axil_wready(axil_xfcp_wready),
    .m_axil_bresp(axil_xfcp_bresp),
    .m_axil_bvalid(axil_xfcp_bvalid),
    .m_axil_bready(axil_xfcp_bready),
    .m_axil_araddr(axil_xfcp_araddr),
    .m_axil_arprot(axil_xfcp_arprot),
    .m_axil_arvalid(axil_xfcp_arvalid),
    .m_axil_arready(axil_xfcp_arready),
    .m_axil_rdata(axil_xfcp_rdata),
    .m_axil_rresp(axil_xfcp_rresp),
    .m_axil_rvalid(axil_xfcp_rvalid),
    .m_axil_rready(axil_xfcp_rready)
);

// AXI between MAC and Ethernet modules
wire [63:0] rx_axis_tdata;
wire [7:0] rx_axis_tkeep;
wire rx_axis_tvalid;
wire rx_axis_tready;
wire rx_axis_tlast;
wire rx_axis_tuser;

wire [63:0] tx_axis_tdata;
wire [7:0] tx_axis_tkeep;
wire tx_axis_tvalid;
wire tx_axis_tready;
wire tx_axis_tlast;
wire tx_axis_tuser;


// Place first payload byte onto LEDs
reg valid_last = 0;
reg [7:0] led_reg = 0;

always @(posedge clk) begin
    if (rst) begin
        led_reg <= 0;
    end else begin
        valid_last <= tx_axis_tlast;
        if (tx_axis_tvalid & ~valid_last) begin
            led_reg <= tx_axis_tdata;
        end
    end
end

assign led = led_reg;

assign sfp1_txd = 64'h0707070707070707;
assign sfp1_txc = 8'hff;
assign sfp2_txd = 64'h0707070707070707;
assign sfp2_txc = 8'hff;
assign sfp3_txd = 64'h0707070707070707;
assign sfp3_txc = 8'hff;

eth_mac_10g_fifo #(
    .ENABLE_PADDING(1),
    .ENABLE_DIC(1),
    .MIN_FRAME_LENGTH(64),
    .TX_FIFO_DEPTH(4096),
    .TX_FRAME_FIFO(1),
    .RX_FIFO_DEPTH(4096),
    .RX_FRAME_FIFO(1)
)
eth_mac_10g_fifo_inst (
    .rx_clk(sfp0_rx_clk),
    .rx_rst(sfp0_rx_rst),
    .tx_clk(sfp0_tx_clk),
    .tx_rst(sfp0_tx_rst),
    .logic_clk(clk),
    .logic_rst(rst),

    .tx_axis_tdata(tx_axis_tdata),
    .tx_axis_tkeep(tx_axis_tkeep),
    .tx_axis_tvalid(tx_axis_tvalid),
    .tx_axis_tready(tx_axis_tready),
    .tx_axis_tlast(tx_axis_tlast),
    .tx_axis_tuser(tx_axis_tuser),

    .rx_axis_tdata(),
    .rx_axis_tkeep(),
    .rx_axis_tvalid(),
    .rx_axis_tready(1'b1),
    .rx_axis_tlast(),
    .rx_axis_tuser(),

    .xgmii_rxd(sfp0_rxd),
    .xgmii_rxc(sfp0_rxc),
    .xgmii_txd(sfp0_txd),
    .xgmii_txc(sfp0_txc),

    .tx_fifo_overflow(),
    .tx_fifo_bad_frame(),
    .tx_fifo_good_frame(),
    .rx_error_bad_frame(),
    .rx_error_bad_fcs(),
    .rx_fifo_overflow(),
    .rx_fifo_bad_frame(),
    .rx_fifo_good_frame(),

    .cfg_ifg(8'd12),
    .cfg_tx_enable(1'b1),
    .cfg_rx_enable(1'b1)
);

// packet generator
packetgen #(
    .DATA_WIDTH(64),
    .FREQUENCY(156250),
    .N_FLOWS(2)
)
packetgen_inst(
    .clk(clk),
    .rst(rst),
    .axis_tdata(tx_axis_tdata),
    .axis_tkeep(tx_axis_tkeep),
    .axis_tvalid(tx_axis_tvalid),
    .axis_tready(tx_axis_tready),
    .axis_tlast(tx_axis_tlast),

    .s_axil_awaddr(axil_xfcp_awaddr),
    .s_axil_awprot(axil_xfcp_awprot),
    .s_axil_awvalid(axil_xfcp_awvalid),
    .s_axil_awready(axil_xfcp_awready),
    .s_axil_wdata(axil_xfcp_wdata),
    .s_axil_wstrb(axil_xfcp_wstrb),
    .s_axil_wvalid(axil_xfcp_wvalid),
    .s_axil_wready(axil_xfcp_wready),
    .s_axil_bresp(axil_xfcp_bresp),
    .s_axil_bvalid(axil_xfcp_bvalid),
    .s_axil_bready(axil_xfcp_bready),
    .s_axil_araddr(axil_xfcp_araddr),
    .s_axil_arprot(axil_xfcp_arprot),
    .s_axil_arvalid(axil_xfcp_arvalid),
    .s_axil_arready(axil_xfcp_arready),
    .s_axil_rdata(axil_xfcp_rdata),
    .s_axil_rresp(axil_xfcp_rresp),
    .s_axil_rvalid(axil_xfcp_rvalid),
    .s_axil_rready(axil_xfcp_rready)

);

assign tx_axis_tuser = 1'b0;

endmodule

`resetall
