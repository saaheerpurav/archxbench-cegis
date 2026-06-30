`timescale 1ns/1ps

module gd_derivative #(
    parameter N = 16,
    parameter M = 8
)(
    input  signed [N-1:0] x,
    input  signed [N-1:0] a,
    input  signed [N-1:0] b,
    output signed [N-1:0] gradient
);

    localparam W = (2 * N) + 1;

    wire signed [(2*N)-1:0] ax_product;
    wire signed [W-1:0]     ax_product_ext;
    wire signed [W-1:0]     two_ax_product;
    wire signed [W-1:0]     scaled_two_ax;
    wire signed [W-1:0]     b_ext;
    wire signed [W-1:0]     gradient_wide;

    assign ax_product      = $signed(a) * $signed(x);
    assign ax_product_ext  = {ax_product[(2*N)-1], ax_product};
    assign two_ax_product  = ax_product_ext <<< 1;
    assign scaled_two_ax   = two_ax_product >>> M;

    assign b_ext           = {{(W-N){b[N-1]}}, b};
    assign gradient_wide   = scaled_two_ax + b_ext;

    assign gradient        = gradient_wide[N-1:0];

endmodule