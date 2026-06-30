`timescale 1ns/1ps

module harris_gradient_products #(
    parameter GRAD_W = 16,
    parameter PROD_W = 32
) (
    input  signed [GRAD_W-1:0] ix,
    input  signed [GRAD_W-1:0] iy,
    output signed [PROD_W-1:0] ix2,
    output signed [PROD_W-1:0] iy2,
    output signed [PROD_W-1:0] ixy
);

    wire signed [(2*GRAD_W)-1:0] ix2_full;
    wire signed [(2*GRAD_W)-1:0] iy2_full;
    wire signed [(2*GRAD_W)-1:0] ixy_full;

    assign ix2_full = ix * ix;
    assign iy2_full = iy * iy;
    assign ixy_full = ix * iy;

    assign ix2 = ix2_full;
    assign iy2 = iy2_full;
    assign ixy = ixy_full;

endmodule