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


module conf_iface #(
    // Number of traffic flows generated by the module
    parameter N_FLOWS = 4
)
(
    input wire clk,
    input wire rst,

    /*
    * AXI lite slave interface
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
    input  wire             s_axil_rready,

    /*
    * Manager configuration interface
    */
    output wire                  cfg_en,
    output wire [FLOW_WIDTH-1:0] cfg_id,

    output wire [47:0]           cfg_d_mac,
    output wire [47:0]           cfg_s_mac,
    output wire [15:0]           cfg_ethertype,
    output wire [7 :0]           cfg_payload
);
    localparam integer FLOW_WIDTH = (N_FLOWS > 1) ? $clog2(N_FLOWS) : 1;

    // Command registers
    reg [31:0]  command_reg;
    reg [47:0]	d_mac_reg;
    reg [47:0]  s_mac_reg;
    reg [15:0]  ethertype_reg;
    reg [7 :0]  payload_reg;
    reg [10:0]	size_reg;
    reg [31:0]  mngr_id_reg;

    reg cfg_en_reg = 0;
    reg [FLOW_WIDTH-1:0] cfg_id_reg;

    assign cfg_en = cfg_en_reg;
    assign cfg_id = cfg_id_reg;

    assign cfg_d_mac        = d_mac_reg;
    assign cfg_s_mac        = s_mac_reg;
    assign cfg_ethertype    = ethertype_reg;
    assign cfg_payload      = payload_reg;

    /*
    * AXI Lite Registe Interface
    */
    wire [32-1:0]    reg_wr_addr;
    wire [32-1:0]    reg_wr_data;
    wire [4-1:0]     reg_wr_strb;
    wire             reg_wr_en;
    wire             reg_wr_wait;
    wire             reg_wr_ack;
    wire [32-1:0]    reg_rd_addr;
    wire             reg_rd_en;
    wire [32-1:0]    reg_rd_data;
    wire             reg_rd_wait;
    wire             reg_rd_ack;
    
    reg    reg_wr_ack_reg;
    assign reg_wr_ack   = reg_wr_ack_reg;

    axil_reg_if #(
        .DATA_WIDTH(32),
        .ADDR_WIDTH(32),
        .STRB_WIDTH(4),
        .TIMEOUT(4)
    ) axil_iface (
        .clk(clk),
        .rst(rst),

        /*
        * AXI lite slave interface
        */
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

        /*
        * Register interface
        */
        .reg_wr_addr(reg_wr_addr),
        .reg_wr_data(reg_wr_data),
        .reg_wr_strb(reg_wr_strb),
        .reg_wr_en(reg_wr_en),
        .reg_wr_wait(reg_wr_wait),
        .reg_wr_ack(reg_wr_ack),
        .reg_rd_addr(reg_rd_addr),
        .reg_rd_en(reg_rd_en),
        .reg_rd_data(reg_rd_data),
        .reg_rd_wait(reg_rd_wait),
        .reg_rd_ack(reg_rd_ack)
    );

    // Input logic
    always @(posedge clk) begin
        if(reg_wr_en) begin
            case (reg_wr_addr)
                32'h0000: begin
                    //command_reg[7 : 0] <= reg_wr_data[31:24];
                end
                32'h0004: begin
                    //Destination MAC field
                    d_mac_reg[31: 0] <= reg_wr_data;
                end
                32'h0008: begin
                    //Destination MAC field (2 lsb)
                    d_mac_reg[47:32] <= reg_wr_data[15: 0];
                end
                32'h000C: begin
                    //Source MAC field
                    s_mac_reg[31: 0] <= reg_wr_data;
                end
                32'h0010: begin
                    //Source MAC field (2 lsb)
                    s_mac_reg[47:32] <= reg_wr_data[15: 0];
                end
                32'h0014: begin
                    //Ethertype field
                    ethertype_reg[15: 0] <= reg_wr_data[15: 0];
                end
                32'h0018: begin
                    //Payload pattern
                    payload_reg[ 7: 0] <= reg_wr_data[ 7: 0];
                end
                32'h001C: begin
                    //Manager ID
                    mngr_id_reg[31:24] <= reg_wr_data[ 7: 0];
                    mngr_id_reg[23:16] <= reg_wr_data[15: 8];
                    mngr_id_reg[15: 8] <= reg_wr_data[23:16];
                    mngr_id_reg[ 7: 0] <= reg_wr_data[31:24];
                end
            endcase
            reg_wr_ack_reg <= 1;
        end else begin
            reg_wr_ack_reg <= 0;
        end
    end

    // Output logic
    always @(posedge clk) begin
        if(reg_wr_addr == 32'h0000 && reg_wr_data[24] == 1) begin
            cfg_id_reg <= mngr_id_reg[FLOW_WIDTH-1:0];
            cfg_en_reg <= 1;
        end else begin
            cfg_en_reg <= 0;
        end
    end

endmodule

`resetall