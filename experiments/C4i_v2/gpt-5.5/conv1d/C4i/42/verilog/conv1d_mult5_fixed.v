`timescale 1ns/1ps

module conv1d_mult5_fixed #(
    parameter DATA_W = 8,
    parameter MAC_W  = 15
) (
    input  [DATA_W-1:0] tap0,
    input  [DATA_W-1:0] tap1,
    input  [DATA_W-1:0] tap2,
    input  [DATA_W-1:0] tap3,
    input  [DATA_W-1:0] tap4,
    output [MAC_W-1:0]  prod0,
    output [MAC_W-1:0]  prod1,
    output [MAC_W-1:0]  prod2,
    output [MAC_W-1:0]  prod3,
    output [MAC_W-1:0]  prod4
);

    wire [MAC_W-1:0] tap0_ext;
    wire [MAC_W-1:0] tap1_ext;
    wire [MAC_W-1:0] tap2_ext;
    wire [MAC_W-1:0] tap3_ext;
    wire [MAC_W-1:0] tap4_ext;

    assign tap0_ext = {{(MAC_W-DATA_W){1'b0}}, tap0};
    assign tap1_ext = {{(MAC_W-DATA_W){1'b0}}, tap1};
    assign tap2_ext = {{(MAC_W-DATA_W){1'b0}}, tap2};
    assign tap3_ext = {{(MAC_W-DATA_W){1'b0}}, tap3};
    assign tap4_ext = {{(MAC_W-DATA_W){1'b0}}, tap4};

    // Fixed kernel coefficients: [2, 8, 12, 8, 2]
    assign prod0 = tap0_ext << 1;                       // 2  * tap0
    assign prod1 = tap1_ext << 3;                       // 8  * tap1
    assign prod2 = (tap2_ext << 3) + (tap2_ext << 2);   // 12 * tap2
    assign prod3 = tap3_ext << 3;                       // 8  * tap3
    assign prod4 = tap4_ext << 1;                       // 2  * tap4

endmodule