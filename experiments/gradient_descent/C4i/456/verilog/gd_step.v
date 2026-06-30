`timescale 1ns/1ps

module gd_step #(
    parameter N = 16,
    parameter M = 8
)(
    input  signed [N-1:0] alpha,
    input  signed [N-1:0] gradient,
    output signed [N-1:0] step
);

    wire signed [(2*N)-1:0] product;
    wire signed [(2*N)-1:0] scaled_product;

    assign product = alpha * gradient;
    assign scaled_product = product >>> M;
    assign step = scaled_product[N-1:0];

endmodule