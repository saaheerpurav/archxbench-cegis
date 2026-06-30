`timescale 1ns/1ps

module sqrt_nr_convergence #(
    parameter N = 16
)(
    input  [N-1:0] y_current,
    input  [N-1:0] y_next,
    output         converged
);

    wire [N-1:0] diff;

    assign diff = (y_current >= y_next) ? (y_current - y_next) :
                                          (y_next - y_current);

    assign converged = (diff <= {{(N-1){1'b0}}, 1'b1});

endmodule