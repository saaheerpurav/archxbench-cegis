`timescale 1ns/1ps

module sqrt_nr_initial_guess #(
    parameter N = 16,
    parameter M = 8
)(
    input  [N-1:0] X,
    output reg [N-1:0] initial_guess
);

    localparam [N-1:0] ONE_FIXED = ({{(N-1){1'b0}}, 1'b1} << M);

    always @(*) begin
        if (X == {N{1'b0}}) begin
            initial_guess = {N{1'b0}};
        end else if (X < ONE_FIXED) begin
            initial_guess = ONE_FIXED;
        end else begin
            initial_guess = X;
        end
    end

endmodule