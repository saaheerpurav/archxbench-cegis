`timescale 1ns/1ps

module sqrt_nr_special_case #(
    parameter N = 16
)(
    input  [N-1:0] X,
    output         is_zero,
    output [N-1:0] special_result
);

    assign is_zero = (X == {N{1'b0}});
    assign special_result = {N{1'b0}};

endmodule