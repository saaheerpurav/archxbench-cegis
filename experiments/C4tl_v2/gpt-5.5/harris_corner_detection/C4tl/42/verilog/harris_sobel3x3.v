`timescale 1ns/1ps

module harris_sobel3x3 #(
    parameter PIXEL_W = 8,
    parameter GRAD_W  = 16
) (
    input  [PIXEL_W-1:0] p00,
    input  [PIXEL_W-1:0] p01,
    input  [PIXEL_W-1:0] p02,
    input  [PIXEL_W-1:0] p10,
    input  [PIXEL_W-1:0] p11,
    input  [PIXEL_W-1:0] p12,
    input  [PIXEL_W-1:0] p20,
    input  [PIXEL_W-1:0] p21,
    input  [PIXEL_W-1:0] p22,
    output signed [GRAD_W-1:0] gx,
    output signed [GRAD_W-1:0] gy
);

    localparam EXT_W = GRAD_W;

    wire signed [EXT_W-1:0] s00 = $signed({1'b0, p00});
    wire signed [EXT_W-1:0] s01 = $signed({1'b0, p01});
    wire signed [EXT_W-1:0] s02 = $signed({1'b0, p02});

    wire signed [EXT_W-1:0] s10 = $signed({1'b0, p10});
    wire signed [EXT_W-1:0] s11 = $signed({1'b0, p11});
    wire signed [EXT_W-1:0] s12 = $signed({1'b0, p12});

    wire signed [EXT_W-1:0] s20 = $signed({1'b0, p20});
    wire signed [EXT_W-1:0] s21 = $signed({1'b0, p21});
    wire signed [EXT_W-1:0] s22 = $signed({1'b0, p22});

    assign gx = (-s00) + s02
              + (-(s10 <<< 1)) + (s12 <<< 1)
              + (-s20) + s22;

    assign gy = (-s00) + (-(s01 <<< 1)) + (-s02)
              + s20 + (s21 <<< 1) + s22;

endmodule