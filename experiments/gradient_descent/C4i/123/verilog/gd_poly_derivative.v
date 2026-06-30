`timescale 1ns/1ps

module gd_poly_derivative #(
    parameter N = 16,
    parameter M = 8,
    parameter GRAD_W = (2*N) + 3
)(
    input  signed [N-1:0] x,
    input  signed [N-1:0] a,
    input  signed [N-1:0] b,
    output signed [GRAD_W-1:0] gradient
);

    localparam PROD_W = 2*N;
    localparam DBL_W  = PROD_W + 1;

    wire signed [PROD_W-1:0] ax_product;
    wire signed [DBL_W-1:0]  doubled_product;
    wire signed [GRAD_W-1:0] scaled_term;
    wire signed [GRAD_W-1:0] b_ext;

    assign ax_product = $signed(a) * $signed(x);

    assign doubled_product =
        {ax_product[PROD_W-1], ax_product} <<< 1;

    assign scaled_term =
        {{(GRAD_W-DBL_W){doubled_product[DBL_W-1]}}, doubled_product} >>> M;

    assign b_ext =
        {{(GRAD_W-N){b[N-1]}}, b};

    assign gradient = scaled_term + b_ext;

endmodule