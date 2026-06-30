`timescale 1ns/1ps

module gd_poly_derivative #(
    parameter N = 16,
    parameter M = 8,
    parameter OUT_W = (2*N) + 2
)(
    input  signed [N-1:0] x,
    input  signed [N-1:0] a,
    input  signed [N-1:0] b,
    output signed [OUT_W-1:0] deriv
);

    wire signed [(2*N)-1:0] ax_product;
    wire signed [(2*N):0] twice_ax;
    wire signed [OUT_W-1:0] twice_ax_ext;
    wire signed [OUT_W-1:0] scaled_twice_ax;
    wire signed [OUT_W-1:0] b_ext;

    assign ax_product = a * x;

    assign twice_ax = {ax_product[(2*N)-1], ax_product} <<< 1;
    assign twice_ax_ext = {{(OUT_W-((2*N)+1)){twice_ax[(2*N)]}}, twice_ax};
    assign scaled_twice_ax = $signed(twice_ax_ext) >>> M;

    assign b_ext = {{(OUT_W-N){b[N-1]}}, b};

    assign deriv = scaled_twice_ax + b_ext;

endmodule