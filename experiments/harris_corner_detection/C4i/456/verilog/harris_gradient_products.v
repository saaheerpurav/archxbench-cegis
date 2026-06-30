`timescale 1ns/1ps

module harris_gradient_products #(
    parameter GRAD_W = 16,
    parameter PROD_W = 32
) (
    input signed [GRAD_W-1:0] ix,
    input signed [GRAD_W-1:0] iy,
    output [PROD_W-1:0] ix2,
    output [PROD_W-1:0] iy2,
    output signed [PROD_W-1:0] ixy
);

    assign ix2 = ix * ix;
    assign iy2 = iy * iy;
    assign ixy = ix * iy;

endmodule