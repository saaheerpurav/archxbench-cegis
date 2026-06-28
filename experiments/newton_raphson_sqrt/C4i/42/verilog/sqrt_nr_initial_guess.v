`timescale 1ns/1ps

module sqrt_nr_initial_guess #(
    parameter N = 16,
    parameter M = 8
)(
    input  [N-1:0] X,
    output reg [N-1:0] initial_y,
    output reg is_zero
);

    /*
     * Return the fixed-point representation of 1.0.
     *
     * For an unsigned Q-format value with M fractional bits,
     * 1.0 is encoded as 1 << M.
     *
     * If M >= N, 1.0 is not representable in N bits, so saturate
     * to the maximum N-bit unsigned value.
     */
    function [N-1:0] fixed_one;
        input dummy;
        integer k;
        begin
            fixed_one = {N{1'b0}};

            if (M < N) begin
                for (k = 0; k < N; k = k + 1) begin
                    if (k == M)
                        fixed_one[k] = 1'b1;
                end
            end else begin
                fixed_one = {N{1'b1}};
            end
        end
    endfunction

    wire [N-1:0] one_value;
    assign one_value = fixed_one(1'b0);

    always @* begin
        is_zero = (X == {N{1'b0}});

        if (is_zero) begin
            initial_y = {N{1'b0}};
        end else if (X < one_value) begin
            initial_y = one_value;
        end else begin
            initial_y = X;
        end
    end

endmodule