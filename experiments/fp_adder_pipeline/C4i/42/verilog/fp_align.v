`timescale 1ns/1ps

module fp_align (
    input        a_sign,
    input  [7:0] a_exp,
    input [23:0] a_sig,

    input        b_sign,
    input  [7:0] b_exp,
    input [23:0] b_sig,

    output reg        large_sign,
    output reg        small_sign,
    output reg [7:0]  large_exp,
    output reg [26:0] large_sig,
    output reg [26:0] small_sig
);

    reg        mag_a_ge_b;
    reg [7:0]  exp_diff;

    reg [7:0]  a_eff_exp;
    reg [7:0]  b_eff_exp;

    reg [26:0] a_ext;
    reg [26:0] b_ext;

    function [26:0] rshift_sticky;
        input [26:0] val;
        input [7:0]  shamt;

        integer i;
        reg sticky;

        begin
            sticky = 1'b0;

            if (shamt == 8'd0) begin
                rshift_sticky = val;
            end else if (shamt >= 8'd27) begin
                rshift_sticky = {26'b0, |val};
            end else begin
                rshift_sticky = val >> shamt;

                for (i = 0; i < 27; i = i + 1) begin
                    if ((i < shamt) && val[i]) begin
                        sticky = 1'b1;
                    end
                end

                rshift_sticky[0] = rshift_sticky[0] | sticky;
            end
        end
    endfunction

    always @* begin
        /*
         * Extend significands with guard, round, and sticky positions.
         *
         * Input significands are expected to be 24 bits:
         *   normal:    {1'b1, fraction[22:0]}
         *   subnormal: {1'b0, fraction[22:0]}
         */
        a_ext = {a_sig, 3'b000};
        b_ext = {b_sig, 3'b000};

        /*
         * Effective exponent for alignment.
         *
         * IEEE-754 subnormals have raw exponent 0, but their arithmetic
         * exponent is the same as raw exponent 1.  For zero, the value of
         * the effective exponent does not affect the shifted significand,
         * because the significand is zero; keeping zero as zero also makes
         * magnitude comparison natural.
         */
        if ((a_exp == 8'd0) && (a_sig != 24'd0))
            a_eff_exp = 8'd1;
        else
            a_eff_exp = a_exp;

        if ((b_exp == 8'd0) && (b_sig != 24'd0))
            b_eff_exp = 8'd1;
        else
            b_eff_exp = b_exp;

        /*
         * Magnitude comparison.
         *
         * Use effective exponent first, then significand.  Ties select A.
         * Selecting A on exact ties gives deterministic behavior and is
         * useful for cancellation cases handled by later stages.
         */
        if (a_eff_exp > b_eff_exp)
            mag_a_ge_b = 1'b1;
        else if (a_eff_exp < b_eff_exp)
            mag_a_ge_b = 1'b0;
        else if (a_sig >= b_sig)
            mag_a_ge_b = 1'b1;
        else
            mag_a_ge_b = 1'b0;

        if (mag_a_ge_b) begin
            exp_diff   = a_eff_exp - b_eff_exp;

            large_sign = a_sign;
            small_sign = b_sign;

            large_exp  = a_exp;
            large_sig  = a_ext;
            small_sig  = rshift_sticky(b_ext, exp_diff);
        end else begin
            exp_diff   = b_eff_exp - a_eff_exp;

            large_sign = b_sign;
            small_sign = a_sign;

            large_exp  = b_exp;
            large_sig  = b_ext;
            small_sig  = rshift_sticky(a_ext, exp_diff);
        end
    end

endmodule