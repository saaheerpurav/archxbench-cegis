`timescale 1ns/1ps

module dct8_sum8 #(
    parameter IN_W  = 28,
    parameter SUM_W = IN_W + 3
) (
    input  signed [IN_W-1:0]  in0,
    input  signed [IN_W-1:0]  in1,
    input  signed [IN_W-1:0]  in2,
    input  signed [IN_W-1:0]  in3,
    input  signed [IN_W-1:0]  in4,
    input  signed [IN_W-1:0]  in5,
    input  signed [IN_W-1:0]  in6,
    input  signed [IN_W-1:0]  in7,
    output signed [SUM_W-1:0] sum
);

    wire signed [SUM_W-1:0] e0;
    wire signed [SUM_W-1:0] e1;
    wire signed [SUM_W-1:0] e2;
    wire signed [SUM_W-1:0] e3;
    wire signed [SUM_W-1:0] e4;
    wire signed [SUM_W-1:0] e5;
    wire signed [SUM_W-1:0] e6;
    wire signed [SUM_W-1:0] e7;

    assign e0 = {{(SUM_W-IN_W){in0[IN_W-1]}}, in0};
    assign e1 = {{(SUM_W-IN_W){in1[IN_W-1]}}, in1};
    assign e2 = {{(SUM_W-IN_W){in2[IN_W-1]}}, in2};
    assign e3 = {{(SUM_W-IN_W){in3[IN_W-1]}}, in3};
    assign e4 = {{(SUM_W-IN_W){in4[IN_W-1]}}, in4};
    assign e5 = {{(SUM_W-IN_W){in5[IN_W-1]}}, in5};
    assign e6 = {{(SUM_W-IN_W){in6[IN_W-1]}}, in6};
    assign e7 = {{(SUM_W-IN_W){in7[IN_W-1]}}, in7};

    assign sum = e0 + e1 + e2 + e3 + e4 + e5 + e6 + e7;

endmodule