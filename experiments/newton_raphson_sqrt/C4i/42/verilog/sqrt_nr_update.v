`timescale 1ns/1ps

module sqrt_nr_update #(
    parameter N = 16
)(
    input  [N-1:0] y,
    input  [N-1:0] quotient,
    output [N-1:0] next_y
);

    wire [N:0] sum_ext;

    assign sum_ext = {1'b0, y} + {1'b0, quotient};

    assign next_y = sum_ext[N:1];

endmodule