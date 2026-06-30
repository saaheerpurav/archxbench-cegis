`timescale 1ns/1ps

module gd_poly_step #(
    parameter N = 16,
    parameter M = 8,
    parameter GRAD_W = (2*N) + 3,
    parameter STEP_W = (3*N) + 4
)(
    input  signed [N-1:0] alpha,
    input  signed [GRAD_W-1:0] gradient,
    output signed [STEP_W-1:0] step
);

    localparam PROD_W = N + GRAD_W;

    wire signed [PROD_W-1:0] product;
    wire signed [STEP_W-1:0] product_ext;

    assign product = $signed(alpha) * $signed(gradient);
    assign product_ext = {{(STEP_W-PROD_W){product[PROD_W-1]}}, product};
    assign step = product_ext >>> M;

endmodule