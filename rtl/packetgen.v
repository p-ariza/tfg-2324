/*

Copyright (c) 2024 Pablo Ariza García

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

*/

`resetall
`timescale 1ns / 10fs
`default_nettype none

module packetgen #(
		parameter DATA_WIDTH=512,
		parameter FREQUENCY = 350000000,
		parameter N_FLOWS = 4,

		//Flow characteristics
		parameter BANDWIDTHS = {32'd1000000000, 32'd1000000000, 32'd1000000000, 32'd1000000000},
		parameter SIZES = {11'd192, 11'd192, 11'd192, 11'd192},

		//Packet contents
		parameter D_MACS = {48'hABCDEF000001, 48'hABCDEF000002, 48'hABCDEF000003, 48'hABCDEF000004},
		parameter S_MACS = {48'hBEEFBEEF0001, 48'hBEEFBEEF0002, 48'hBEEFBEEF0003, 48'hBEEFBEEF0004},
		parameter ETHERTYPES = {16'h0800, 16'h0800, 16'h0800, 16'h0800}, 
		parameter PAYLOADS = {8'hAA, 8'hBB, 8'hCC, 8'hDD}

	)
	(
		input wire clk,
		input wire rst,

		/*
		* AXI Stream Output
		*/
		//input  wire						axis_tready,
		output wire [DATA_WIDTH-1:0]	axis_tdata,
		output wire [DATA_WIDTH/8-1:0]	axis_tkeep,
		output wire 					axis_tvalid,
		output wire 					axis_tlast,

		/*
		* Flow Configuration AXI lite slave interface
		*/
		input  wire [32-1:0]    s_axil_awaddr,
		input  wire [2:0]       s_axil_awprot,
		input  wire             s_axil_awvalid,
		output wire             s_axil_awready,
		input  wire [32-1:0]    s_axil_wdata,
		input  wire [4-1:0]     s_axil_wstrb,
		input  wire             s_axil_wvalid,
		output wire             s_axil_wready,
		output wire [1:0]       s_axil_bresp,
		output wire             s_axil_bvalid,
		input  wire             s_axil_bready,
		input  wire [32-1:0]    s_axil_araddr,
		input  wire [2:0]       s_axil_arprot,
		input  wire             s_axil_arvalid,
		output wire             s_axil_arready,
		output wire [32-1:0]    s_axil_rdata,
		output wire [1:0]       s_axil_rresp,
		output wire             s_axil_rvalid,
		input  wire             s_axil_rready
	);

	//Debug purposes
	reg [11*N_FLOWS-1:0] sizes_reg = SIZES;
	reg [32*N_FLOWS-1:0] bandwidths_reg = BANDWIDTHS;

	reg [48*N_FLOWS-1:0] d_macs_reg = D_MACS;
	reg [48*N_FLOWS-1:0] s_macs_reg = S_MACS;
	reg [16*N_FLOWS-1:0] ethertypes_reg = ETHERTYPES;
	reg [ 8*N_FLOWS-1:0] payloads_reg = PAYLOADS;

	//Packet Builder - FIFO Interface
	wire [130:0] fifo_rd_data;
	wire fifo_rd_enable;
	wire fifo_rd_valid;

    packet_builder #(
		.DATA_WIDTH(DATA_WIDTH)
	) builder (
		.clk(clk), 
		.rst(rst),

		.fifo_rd_enable(fifo_rd_enable),
		.fifo_rd_valid(fifo_rd_valid),
 
		.size			(fifo_rd_data[130:120]), 
		.d_mac			(fifo_rd_data[119:72]),
		.s_mac			(fifo_rd_data[71:24]),
		.ethertype		(fifo_rd_data[23:8]),
		.payload		(fifo_rd_data[7:0]),

		.axis_tvalid(axis_tvalid), 
		.axis_tlast(axis_tlast), 
		.axis_tkeep(axis_tkeep), 
		.axis_tdata(axis_tdata)
	);

	//Managers - FIFO Interface
	wire [130:0] fifo_wr_data;
	wire [N_FLOWS-1:0] manager_wr_enable;
	wire fifo_wr_ready;
	
	//Arbiter Interface
	wire [N_FLOWS-1:0] manager_request;
	wire [N_FLOWS-1:0] manager_ack;
	wire [N_FLOWS-1:0] manager_grant;

	arbiter #(
		.PORTS(N_FLOWS),
		.ARB_BLOCK(1),
		.ARB_BLOCK_ACK(1)
	) flow_arbiter (
		.clk(clk),
		.rst(rst),

		.request(manager_request),
		.acknowledge(manager_ack),
		.grant(manager_grant)
	);
	
	//Manager configuration interface
	localparam integer FLOW_WIDTH = (N_FLOWS > 1) ? $clog2(N_FLOWS) : 1;
	wire                  cfg_en;
    wire [FLOW_WIDTH-1:0] cfg_id;
	wire [47:0]           cfg_d_mac;
    wire [47:0]           cfg_s_mac;
    wire [15:0]           cfg_ethertype;
    wire [7 :0]           cfg_payload;

	conf_iface #(
		.N_FLOWS(N_FLOWS)
	) manager_config (
		.clk(clk),
		.rst(rst),

		.s_axil_awaddr(s_axil_awaddr),
		.s_axil_awprot(s_axil_awprot),
		.s_axil_awvalid(s_axil_awvalid),
		.s_axil_awready(s_axil_awready),
		.s_axil_wdata(s_axil_wdata),
		.s_axil_wstrb(s_axil_wstrb),
		.s_axil_wvalid(s_axil_wvalid),
		.s_axil_wready(s_axil_wready),
		.s_axil_bresp(s_axil_bresp),
		.s_axil_bvalid(s_axil_bvalid),
		.s_axil_bready(s_axil_bready),
		.s_axil_araddr(s_axil_araddr),
		.s_axil_arprot(s_axil_arprot),
		.s_axil_arvalid(s_axil_arvalid),
		.s_axil_arready(s_axil_arready),
		.s_axil_rdata(s_axil_rdata),
		.s_axil_rresp(s_axil_rresp),
		.s_axil_rvalid(s_axil_rvalid),
		.s_axil_rready(s_axil_rready),

		.cfg_en(cfg_en),
		.cfg_id(cfg_id),
		.cfg_d_mac(cfg_d_mac),
		.cfg_s_mac(cfg_s_mac),
		.cfg_ethertype(cfg_ethertype),
		.cfg_payload(cfg_payload)
	);

	wire [N_FLOWS*131-1:0] manager_data;
	genvar i;
	generate
		for (i=0; i < N_FLOWS; i = i+1) begin
			packet_manager #(
				.ID(i),
				.FREQUENCY(FREQUENCY),
				.N_FLOWS(N_FLOWS),

				.SIZE(SIZES[11*(i+1)-1:11*i]),
				.BANDWIDTH(BANDWIDTHS[32*(i+1)-1:32*i]),

				.MAC_D(D_MACS[48*(i+1)-1:48*i]),
				.MAC_S(S_MACS[48*(i+1)-1:48*i]),
				.ETHERTYPE(ETHERTYPES[16*(i+1)-1:16*i]),
				.PAYLOAD(PAYLOADS[8*(i+1)-1:8*i])
			) manager (
				.clk(clk),
				.rst(rst),

				.arb_request(manager_request[i]),
				.arb_ack(manager_ack[i]),
				.arb_grant(manager_grant[i]),

				.fifo_wr_enable(manager_wr_enable[i]),
				.fifo_wr_ready(fifo_wr_ready),

				.size			(manager_data[(i*131+130):(i*131+120)]),
				.d_mac			(manager_data[(i*131+119):(i*131+72)]),
				.s_mac			(manager_data[(i*131+71) :(i*131+24)]),
				.ethertype		(manager_data[(i*131+23) :(i*131+8)]),
				.payload		(manager_data[(i*131+7)  :(i*131)]),

				.cfg_en(cfg_en),
				.cfg_id(cfg_id),
				.cfg_d_mac(cfg_d_mac),
				.cfg_s_mac(cfg_s_mac),
				.cfg_ethertype(cfg_ethertype),
				.cfg_payload(cfg_payload)
			);
		end
	endgenerate

	reg [N_FLOWS-1:0] manager_wr_enable_reg = {N_FLOWS{1'b0}};
	reg [131-1:0] manager_data_reg;

	integer j;
	always @(posedge clk) begin
		if (rst) begin
			manager_wr_enable_reg <= {N_FLOWS{1'b0}};
		end

		manager_wr_enable_reg <= manager_wr_enable;

		for (j=0; j < N_FLOWS; j = j+1) begin
			if(manager_wr_enable[j]) begin
				manager_data_reg[131-1:0] <= manager_data[j*131 +: 131];
			end
		end
	end

	switch_simple_fifo #(
		.DEPTH(8),
		.DATA_WIDTH(131)
	) command_fifo (
		.clk(clk),
		.rst(rst),

		.wr_data(manager_data_reg),
		.wr_enable(|manager_wr_enable_reg),
		.wr_ready(fifo_wr_ready),

		.wr_sof(1'b0),
		.wr_eof(1'b0),
		.wr_drop(1'b0),

		.rd_data(fifo_rd_data),
		.rd_enable(fifo_rd_enable),
		.rd_valid(fifo_rd_valid),

		.rd_sof(1'b0),
		.rd_eof(1'b0),
		.rd_drop(1'b0)
	);

endmodule