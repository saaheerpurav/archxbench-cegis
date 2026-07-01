`timescale 1ns/1ps

module dct1d_8_mac #(
    parameter DATA_W  = 12,
    parameter COEFF_W = 16,
    parameter ACC_W   = DATA_W + COEFF_W + 4
) (
    input  signed [DATA_W-1:0]  x0,
    input  signed [DATA_W-1:0]  x1,
    input  signed [DATA_W-1:0]  x2,
    input  signed [DATA_W-1:0]  x3,
    input  signed [DATA_W-1:0]  x4,
    input  signed [DATA_W-1:0]  x5,
    input  signed [DATA_W-1:0]  x6,
    input  signed [DATA_W-1:0]  x7,

    input  signed [COEFF_W-1:0] c0,
    input  signed [COEFF_W-1:0] c1,
    input  signed [COEFF_W-1:0] c2,
    input  signed [COEFF_W-1:0] c3,
    input  signed [COEFF_W-1:0] c4,
    input  signed [COEFF_W-1:0] c5,
    input  signed [COEFF_W-1:0] c6,
    input  signed [COEFF_W-1:0] c7,

    output signed [ACC_W-1:0]   sum
);

    localparam PROD_W = DATA_W + COEFF_W;

    wire signed [PROD_W-1:0] p0 = x0 * c0;
    wire signed [PROD_W-1:0] p1 = x1 * c1;
    wire signed [PROD_W-1:0] p2 = x2 * c2;
    wire signed [PROD_W-1:0] p3 = x3 * c3;
    wire signed [PROD_W-1:0] p4 = x4 * c4;
    wire signed [PROD_W-1:0] p5 = x5 * c5;
    wire signed [PROD_W-1:0] p6 = x6 * c6;
    wire signed [PROD_W-1:0] p7 = x7 * c7;

    wire signed [ACC_W-1:0] e0 = p0;
    wire signed [ACC_W-1:0] e1 = p1;
    wire signed [ACC_W-1:0] e2 = p2;
    wire signed [ACC_W-1:0] e3 = p3;
    wire signed [ACC_W-1:0] e4 = p4;
    wire signed [ACC_W-1:0] e5 = p5;
    wire signed [ACC_W-1:0] e6 = p6;
    wire signed [ACC_W-1:0] e7 = p7;

    assign sum = e0 + e1 + e2 + e3 + e4 + e5 + e6 + e7;

endmodule