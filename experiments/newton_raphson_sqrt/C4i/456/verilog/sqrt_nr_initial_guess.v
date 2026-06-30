`timescale 1ns/1ps

module sqrt_nr_initial_guess #(
    parameter N = 16,
    parameter M = 8
)(
    input  [N-1:0] x_in,
    output         x_is_zero,
    output [N-1:0] initial_y
);

    localparam [N-1:0] ONE_FIXED = {{(N-1){1'b0}}, 1'b1} << M;

    assign x_is_zero = (x_in == {N{1'b0}});

    assign initial_y = x_is_zero       ? {N{1'b0}} :
                       (x_in > ONE_FIXED) ? x_in :
                                             ONE_FIXED;

endmodule