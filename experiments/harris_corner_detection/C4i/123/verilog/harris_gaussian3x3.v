`timescale 1ns/1ps

module harris_gaussian3x3 #(
    parameter IN_W  = 32,
    parameter OUT_W = 36
) (
    input  signed [IN_W-1:0] p00,
    input  signed [IN_W-1:0] p01,
    input  signed [IN_W-1:0] p02,
    input  signed [IN_W-1:0] p10,
    input  signed [IN_W-1:0] p11,
    input  signed [IN_W-1:0] p12,
    input  signed [IN_W-1:0] p20,
    input  signed [IN_W-1:0] p21,
    input  signed [IN_W-1:0] p22,
    output signed [OUT_W-1:0] smooth
);

    localparam ACC_W = (OUT_W + 4 > IN_W + 8) ? OUT_W + 4 : IN_W + 8;

    wire signed [ACC_W-1:0] e00 = {{(ACC_W-IN_W){p00[IN_W-1]}}, p00};
    wire signed [ACC_W-1:0] e01 = {{(ACC_W-IN_W){p01[IN_W-1]}}, p01};
    wire signed [ACC_W-1:0] e02 = {{(ACC_W-IN_W){p02[IN_W-1]}}, p02};
    wire signed [ACC_W-1:0] e10 = {{(ACC_W-IN_W){p10[IN_W-1]}}, p10};
    wire signed [ACC_W-1:0] e11 = {{(ACC_W-IN_W){p11[IN_W-1]}}, p11};
    wire signed [ACC_W-1:0] e12 = {{(ACC_W-IN_W){p12[IN_W-1]}}, p12};
    wire signed [ACC_W-1:0] e20 = {{(ACC_W-IN_W){p20[IN_W-1]}}, p20};
    wire signed [ACC_W-1:0] e21 = {{(ACC_W-IN_W){p21[IN_W-1]}}, p21};
    wire signed [ACC_W-1:0] e22 = {{(ACC_W-IN_W){p22[IN_W-1]}}, p22};

    wire signed [ACC_W-1:0] row0 = e00 + (e01 <<< 1) + e02;
    wire signed [ACC_W-1:0] row1 = e10 + (e11 <<< 1) + e12;
    wire signed [ACC_W-1:0] row2 = e20 + (e21 <<< 1) + e22;

    wire signed [ACC_W-1:0] weighted_sum = row0 + (row1 <<< 1) + row2;
    wire signed [ACC_W-1:0] normalized   = weighted_sum >>> 4;

    assign smooth = normalized[OUT_W-1:0];

endmodule