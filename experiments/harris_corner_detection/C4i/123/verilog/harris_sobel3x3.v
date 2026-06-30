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
    output signed [GRAD_W-1:0] ix,
    output signed [GRAD_W-1:0] iy
);

    localparam SAFE_W = PIXEL_W + 3;
    localparam CALC_W = (GRAD_W > SAFE_W) ? GRAD_W : SAFE_W;

    function [PIXEL_W-1:0] clean_pixel;
        input [PIXEL_W-1:0] pix;
        integer i;
        begin
            for (i = 0; i < PIXEL_W; i = i + 1)
                clean_pixel[i] = (pix[i] === 1'b1) ? 1'b1 : 1'b0;
        end
    endfunction

    wire signed [CALC_W-1:0] a00 = {{(CALC_W-PIXEL_W){1'b0}}, clean_pixel(p00)};
    wire signed [CALC_W-1:0] a01 = {{(CALC_W-PIXEL_W){1'b0}}, clean_pixel(p01)};
    wire signed [CALC_W-1:0] a02 = {{(CALC_W-PIXEL_W){1'b0}}, clean_pixel(p02)};
    wire signed [CALC_W-1:0] a10 = {{(CALC_W-PIXEL_W){1'b0}}, clean_pixel(p10)};
    wire signed [CALC_W-1:0] a12 = {{(CALC_W-PIXEL_W){1'b0}}, clean_pixel(p12)};
    wire signed [CALC_W-1:0] a20 = {{(CALC_W-PIXEL_W){1'b0}}, clean_pixel(p20)};
    wire signed [CALC_W-1:0] a21 = {{(CALC_W-PIXEL_W){1'b0}}, clean_pixel(p21)};
    wire signed [CALC_W-1:0] a22 = {{(CALC_W-PIXEL_W){1'b0}}, clean_pixel(p22)};

    assign ix = (a02 + (a12 <<< 1) + a22) -
                (a00 + (a10 <<< 1) + a20);

    assign iy = (a20 + (a21 <<< 1) + a22) -
                (a00 + (a01 <<< 1) + a02);

endmodule