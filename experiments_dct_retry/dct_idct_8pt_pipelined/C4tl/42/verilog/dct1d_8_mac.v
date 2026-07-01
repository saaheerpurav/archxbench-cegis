`timescale 1ns/1ps

module dct1d_8_mac #(
    parameter DATA_W  = 12,
    parameter COEFF_W = 16,
    parameter ACC_W   = 32
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
    output signed [ACC_W-1:0]   acc
);

    localparam PROD_W = DATA_W + COEFF_W;
    localparam SUM_W  = PROD_W + 3;
    localparam WORK_W = (ACC_W > SUM_W) ? ACC_W : SUM_W;

    wire signed [PROD_W-1:0] p0 = x0 * c0;
    wire signed [PROD_W-1:0] p1 = x1 * c1;
    wire signed [PROD_W-1:0] p2 = x2 * c2;
    wire signed [PROD_W-1:0] p3 = x3 * c3;
    wire signed [PROD_W-1:0] p4 = x4 * c4;
    wire signed [PROD_W-1:0] p5 = x5 * c5;
    wire signed [PROD_W-1:0] p6 = x6 * c6;
    wire signed [PROD_W-1:0] p7 = x7 * c7;

    wire signed [WORK_W-1:0] s0 = {{(WORK_W-PROD_W){p0[PROD_W-1]}}, p0};
    wire signed [WORK_W-1:0] s1 = {{(WORK_W-PROD_W){p1[PROD_W-1]}}, p1};
    wire signed [WORK_W-1:0] s2 = {{(WORK_W-PROD_W){p2[PROD_W-1]}}, p2};
    wire signed [WORK_W-1:0] s3 = {{(WORK_W-PROD_W){p3[PROD_W-1]}}, p3};
    wire signed [WORK_W-1:0] s4 = {{(WORK_W-PROD_W){p4[PROD_W-1]}}, p4};
    wire signed [WORK_W-1:0] s5 = {{(WORK_W-PROD_W){p5[PROD_W-1]}}, p5};
    wire signed [WORK_W-1:0] s6 = {{(WORK_W-PROD_W){p6[PROD_W-1]}}, p6};
    wire signed [WORK_W-1:0] s7 = {{(WORK_W-PROD_W){p7[PROD_W-1]}}, p7};

    wire signed [WORK_W-1:0] sum =
        s0 + s1 + s2 + s3 + s4 + s5 + s6 + s7;

    assign acc = sum[ACC_W-1:0];

endmodule