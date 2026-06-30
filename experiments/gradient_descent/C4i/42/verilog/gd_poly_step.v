`timescale 1ns/1ps

module gd_poly_step #(
    parameter N = 16,
    parameter M = 8,
    parameter DERIV_W = (2*N) + 2,
    parameter OUT_W = DERIV_W + N
)(
    input signed [N-1:0] alpha,
    input signed [DERIV_W-1:0] deriv,
    output signed [OUT_W-1:0] step
);

    wire signed [OUT_W-1:0] product;

    assign product = alpha * deriv;
    assign step = product >>> M;

endmodule