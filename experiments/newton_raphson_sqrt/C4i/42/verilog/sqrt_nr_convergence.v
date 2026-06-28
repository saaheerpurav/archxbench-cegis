`timescale 1ns/1ps

module sqrt_nr_convergence #(
    parameter N = 16
)(
    input  [N-1:0] current_y,
    input  [N-1:0] next_y,
    output         converged
);

    wire [N-1:0] abs_diff;

    assign abs_diff = (current_y >= next_y) ?
                      (current_y - next_y) :
                      (next_y - current_y);

    assign converged = (abs_diff <= {{(N-1){1'b0}}, 1'b1});

endmodule