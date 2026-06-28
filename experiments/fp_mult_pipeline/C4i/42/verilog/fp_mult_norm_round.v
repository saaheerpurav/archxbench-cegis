`timescale 1ns/1ps

module fp_mult_norm_round (
    input  [47:0] product,
    input  signed [10:0] exp_in,
    output reg signed [10:0] exp_out,
    output reg [22:0] frac_out,
    output reg overflow,
    output reg underflow
);

    reg signed [10:0] exp_norm;
    reg [47:0] shifted;

    reg [23:0] sig24;
    reg guard_bit;
    reg round_bit;
    reg sticky_bit;

    reg round_inc;
    reg [24:0] rounded;

    reg found;
    reg [5:0] lshift;
    integer i;

    always @* begin
        exp_norm   = 11'sd0;
        shifted    = 48'd0;

        sig24      = 24'd0;
        guard_bit  = 1'b0;
        round_bit  = 1'b0;
        sticky_bit = 1'b0;

        round_inc  = 1'b0;
        rounded    = 25'd0;

        found      = 1'b0;
        lshift     = 6'd0;

        exp_out    = 11'sd0;
        frac_out   = 23'd0;
        overflow   = 1'b0;
        underflow  = 1'b0;

        if (product == 48'd0) begin
            /*
             * A zero product is handled as zero by the downstream packer.
             * Mark it as underflow as well; zero priority should dominate.
             */
            exp_out   = 11'sd0;
            frac_out  = 23'd0;
            overflow  = 1'b0;
            underflow = 1'b1;
        end else begin
            if (product[47]) begin
                /*
                 * Product significand is in [2.0, 4.0).
                 * Normalize by shifting right one place, which is equivalent
                 * to selecting bits [47:24] and incrementing the exponent.
                 */
                exp_norm   = exp_in + 11'sd1;
                sig24      = product[47:24];
                guard_bit  = product[23];
                round_bit  = product[22];
                sticky_bit = |product[21:0];
            end else begin
                /*
                 * Product is below 2.0.  For normal * normal, product[46]
                 * is already set.  For subnormal-related products, search
                 * for the leading one below bit 46 and left-normalize it
                 * into bit 46.
                 */
                found  = 1'b0;
                lshift = 6'd0;

                for (i = 46; i >= 0; i = i - 1) begin
                    if (!found && product[i]) begin
                        lshift = 46 - i;
                        found  = 1'b1;
                    end
                end

                shifted  = product << lshift;
                exp_norm = exp_in - $signed({5'd0, lshift});

                sig24      = shifted[46:23];
                guard_bit  = shifted[22];
                round_bit  = shifted[21];
                sticky_bit = |shifted[20:0];
            end

            /*
             * Round to nearest, ties to even.
             *
             * guard round sticky == 100 is exactly halfway, so increment only
             * if the retained significand is odd.
             */
            round_inc = guard_bit &&
                        (round_bit || sticky_bit || sig24[0]);

            rounded = {1'b0, sig24} + {24'd0, round_inc};

            if (rounded[24]) begin
                /*
                 * Rounding produced 10.000..., so renormalize right by one
                 * and increment the exponent.
                 */
                exp_out  = exp_norm + 11'sd1;
                frac_out = rounded[23:1];
            end else begin
                exp_out  = exp_norm;
                frac_out = rounded[22:0];
            end

            overflow  = (exp_out >= 11'sd255);
            underflow = (exp_out <  11'sd1);
        end
    end

endmodule