`timescale 1ns/1ps

module conv1d_mac5 #(
    parameter MAC_W = 15
) (
    input  [MAC_W-1:0] prod0,
    input  [MAC_W-1:0] prod1,
    input  [MAC_W-1:0] prod2,
    input  [MAC_W-1:0] prod3,
    input  [MAC_W-1:0] prod4,
    output [MAC_W-1:0] mac_sum
);

    /*
     * Sum five unsigned product terms.
     *
     * A sum of five MAC_W-bit unsigned values can require up to MAC_W+3 bits
     * in the most general case.  The top-level design is expected to choose
     * MAC_W large enough to hold the convolution MAC value, but widening the
     * internal adder tree avoids unintended truncation in intermediate terms.
     */
    wire [MAC_W:0]   sum01;
    wire [MAC_W:0]   sum23;
    wire [MAC_W+1:0] sum0123;
    wire [MAC_W+2:0] sum_all;

    assign sum01   = {1'b0, prod0} + {1'b0, prod1};
    assign sum23   = {1'b0, prod2} + {1'b0, prod3};
    assign sum0123 = {1'b0, sum01} + {1'b0, sum23};
    assign sum_all = {1'b0, sum0123} + {{2{1'b0}}, prod4};

    assign mac_sum = sum_all[MAC_W-1:0];

endmodule