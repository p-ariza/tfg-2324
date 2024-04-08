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

module basic_counter #(
    parameter TOTAL_COUNT=3
    )(
    input wire clk,
    input wire rst,
    input wire input_sig,
    output reg output_sig
);  
    localparam pow2 = !(TOTAL_COUNT & (TOTAL_COUNT-1));
    localparam COUNT_WIDTH = pow2 ? $clog2(TOTAL_COUNT)+1 : $clog2(TOTAL_COUNT);

    reg [COUNT_WIDTH-1:0] count;
    //Rising Edge
    always @(posedge clk or posedge rst) begin
        if (rst || (count == TOTAL_COUNT)) begin
            count <= 0;
            output_sig <= 1;
        end else if (input_sig) begin
            count <= count + 1;
            output_sig <= 0;
        end
    end
endmodule :basic_counter