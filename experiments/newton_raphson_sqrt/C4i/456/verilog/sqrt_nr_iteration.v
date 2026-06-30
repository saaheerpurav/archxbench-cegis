`timescale 1ns/1ps

module sqrt_nr_iteration #(
    parameter N = 16
)(
    input  [N-1:0] y_in,
    input  [N-1:0] div_term,
    output [N-1:0] y_next
);

    wire [N:0] sum_ext;

    assign sum_ext = {1'b0, y_in} + {1'b0, div_term};
    assign y_next = sum_ext[N:1];

endmodule