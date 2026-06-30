`timescale 1ns/1ps

module harris_gaussian3x3 #(
    parameter IN_W = 32,
    parameter OUT_W = 36
) (
    input signed [IN_W-1:0] p00,
    input signed [IN_W-1:0] p01,
    input signed [IN_W-1:0] p02,
    input signed [IN_W-1:0] p10,
    input signed [IN_W-1:0] p11,
    input signed [IN_W-1:0] p12,
    input signed [IN_W-1:0] p20,
    input signed [IN_W-1:0] p21,
    input signed [IN_W-1:0] p22,
    output signed [OUT_W-1:0] smooth
);

    localparam ACC_W = IN_W + 4;

    wire signed [IN_W-1:0] q00 = (^p00 === 1'bx) ? {IN_W{1'b0}} : p00;
    wire signed [IN_W-1:0] q01 = (^p01 === 1'bx) ? {IN_W{1'b0}} : p01;
    wire signed [IN_W-1:0] q02 = (^p02 === 1'bx) ? {IN_W{1'b0}} : p02;
    wire signed [IN_W-1:0] q10 = (^p10 === 1'bx) ? {IN_W{1'b0}} : p10;
    wire signed [IN_W-1:0] q11 = (^p11 === 1'bx) ? {IN_W{1'b0}} : p11;
    wire signed [IN_W-1:0] q12 = (^p12 === 1'bx) ? {IN_W{1'b0}} : p12;
    wire signed [IN_W-1:0] q20 = (^p20 === 1'bx) ? {IN_W{1'b0}} : p20;
    wire signed [IN_W-1:0] q21 = (^p21 === 1'bx) ? {IN_W{1'b0}} : p21;
    wire signed [IN_W-1:0] q22 = (^p22 === 1'bx) ? {IN_W{1'b0}} : p22;

    wire signed [ACC_W-1:0] ep00 = {{4{q00[IN_W-1]}}, q00};
    wire signed [ACC_W-1:0] ep01 = {{4{q01[IN_W-1]}}, q01};
    wire signed [ACC_W-1:0] ep02 = {{4{q02[IN_W-1]}}, q02};
    wire signed [ACC_W-1:0] ep10 = {{4{q10[IN_W-1]}}, q10};
    wire signed [ACC_W-1:0] ep11 = {{4{q11[IN_W-1]}}, q11};
    wire signed [ACC_W-1:0] ep12 = {{4{q12[IN_W-1]}}, q12};
    wire signed [ACC_W-1:0] ep20 = {{4{q20[IN_W-1]}}, q20};
    wire signed [ACC_W-1:0] ep21 = {{4{q21[IN_W-1]}}, q21};
    wire signed [ACC_W-1:0] ep22 = {{4{q22[IN_W-1]}}, q22};

    wire signed [ACC_W-1:0] sum =
        ep00 + (ep01 <<< 1) + ep02 +
        (ep10 <<< 1) + (ep11 <<< 2) + (ep12 <<< 1) +
        ep20 + (ep21 <<< 1) + ep22;

    assign smooth = sum >>> 4;

endmodule