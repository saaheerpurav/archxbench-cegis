`timescale 1ns/1ps

module sqrt_nr_divide #(
    parameter N = 16,
    parameter M = 8
)(
    input  [N-1:0] x_in,
    input  [N-1:0] y_in,
    output [N-1:0] quotient
);

    localparam W = (2 * N) + M;

    wire [W-1:0] dividend;
    wire [W-1:0] raw_quotient;
    wire         overflow;

    assign dividend = {{(W-N){1'b0}}, x_in} << M;

    assign raw_quotient = (y_in == {N{1'b0}})
                         ? {W{1'b0}}
                         : (dividend / y_in);

    assign overflow = |raw_quotient[W-1:N];

    assign quotient = overflow ? {N{1'b1}} : raw_quotient[N-1:0];

endmodule