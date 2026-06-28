`timescale 1ns/1ps

module fp_round_nearest_even (
    input  [23:0] significand_norm,
    input  signed [12:0] exponent_norm,
    input  guard_bit,
    input  round_bit,
    input  sticky_bit,
    output reg [23:0] significand_rounded,
    output reg signed [12:0] exponent_rounded
);

    reg increment;
    reg [24:0] rounded_ext;

    always @* begin
        /*
         * IEEE round-to-nearest-even:
         *
         * guard round sticky | action
         * -------------------+-------------------------------
         *   0     x     x    | less than half, do not round up
         *   1     1     x    | greater than half, round up
         *   1     x     1    | greater than half, round up
         *   1     0     0    | exactly half, round to even
         *
         * For the exact-half case, round up only if the current LSB is 1,
         * making the final result even.
         */
        increment = guard_bit && (round_bit || sticky_bit || significand_norm[0]);

        /*
         * Add the rounding increment using one extra bit so that a carry out
         * of the 24-bit significand can be detected.
         */
        rounded_ext = {1'b0, significand_norm} + (increment ? 25'd1 : 25'd0);

        /*
         * If rounding produced a carry, the significand became 10.000...
         * in normalized form. Shift right by one and increment the exponent.
         */
        if (rounded_ext[24]) begin
            significand_rounded = rounded_ext[24:1];
            exponent_rounded    = exponent_norm + 13'sd1;
        end else begin
            significand_rounded = rounded_ext[23:0];
            exponent_rounded    = exponent_norm;
        end
    end

endmodule