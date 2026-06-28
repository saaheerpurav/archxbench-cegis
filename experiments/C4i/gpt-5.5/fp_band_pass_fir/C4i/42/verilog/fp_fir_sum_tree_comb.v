`timescale 1ns/1ps

module fp_fir_sum_tree_comb #(
    parameter TAP_CNT = 63
) (
    input  [TAP_CNT*32-1:0] products_flat,
    output [31:0]           sum_out
);

    /*
     * Right shift with sticky-bit jam.
     *
     * The input significand contains 24 payload bits plus 3 extra
     * guard/round/sticky bits.  Any nonzero bit shifted out is ORed into
     * bit 0.
     */
    function automatic [26:0] shr_jam_27;
        input [26:0] value;
        input [7:0]  shamt;

        reg [26:0] shifted;
        reg [26:0] mask;
        begin
            if (shamt == 0) begin
                shr_jam_27 = value;
            end else if (shamt >= 27) begin
                shr_jam_27 = {26'b0, |value};
            end else begin
                shifted = value >> shamt;
                mask    = (27'h1 << shamt) - 27'h1;
                shifted[0] = shifted[0] | (|(value & mask));
                shr_jam_27 = shifted;
            end
        end
    endfunction


    /*
     * IEEE-754 single precision combinational adder.
     *
     * Implements round-to-nearest-even.  This is intended for FIR
     * accumulation of multiplier outputs, but also includes handling for
     * zeros, subnormals, infinities, and NaNs.
     */
    function automatic [31:0] fp32_add;
        input [31:0] a;
        input [31:0] b;

        reg        sign_a;
        reg        sign_b;
        reg [7:0]  exp_a;
        reg [7:0]  exp_b;
        reg [22:0] frac_a;
        reg [22:0] frac_b;

        reg        a_is_zero;
        reg        b_is_zero;
        reg        a_is_nan;
        reg        b_is_nan;
        reg        a_is_inf;
        reg        b_is_inf;

        reg [23:0] sig_a;
        reg [23:0] sig_b;
        reg [7:0]  exp_eff_a;
        reg [7:0]  exp_eff_b;

        reg        sign_big;
        reg        sign_small;
        reg [7:0]  exp_big;
        reg [7:0]  exp_small;
        reg [23:0] sig_big;
        reg [23:0] sig_small;

        reg [7:0]  shift_amt;
        reg [26:0] mant_big;
        reg [26:0] mant_small;
        reg [27:0] mant_sum;
        reg [26:0] mant_res;

        reg        sign_res;
        reg signed [10:0] exp_res;

        reg        guard_bit;
        reg        round_bit;
        reg        sticky_bit;
        reg        round_inc;
        reg [23:0] mant24;
        reg [24:0] rounded;

        integer k;
        begin
            sign_a = a[31];
            sign_b = b[31];
            exp_a  = a[30:23];
            exp_b  = b[30:23];
            frac_a = a[22:0];
            frac_b = b[22:0];

            a_is_zero = (exp_a == 8'h00) && (frac_a == 23'h000000);
            b_is_zero = (exp_b == 8'h00) && (frac_b == 23'h000000);
            a_is_nan  = (exp_a == 8'hff) && (frac_a != 23'h000000);
            b_is_nan  = (exp_b == 8'hff) && (frac_b != 23'h000000);
            a_is_inf  = (exp_a == 8'hff) && (frac_a == 23'h000000);
            b_is_inf  = (exp_b == 8'hff) && (frac_b == 23'h000000);

            if (a_is_nan || b_is_nan) begin
                fp32_add = 32'h7fc00000;
            end else if (a_is_inf && b_is_inf && (sign_a != sign_b)) begin
                fp32_add = 32'h7fc00000;
            end else if (a_is_inf) begin
                fp32_add = a;
            end else if (b_is_inf) begin
                fp32_add = b;
            end else if (a_is_zero && b_is_zero) begin
                /*
                 * IEEE round-to-nearest gives +0 for +0 + -0.
                 * For -0 + -0, preserve -0.
                 */
                fp32_add = {(sign_a & sign_b), 31'h00000000};
            end else if (a_is_zero) begin
                fp32_add = b;
            end else if (b_is_zero) begin
                fp32_add = a;
            end else begin
                /*
                 * For subnormals, the effective exponent used for alignment
                 * is 1, with no hidden leading one.
                 */
                sig_a     = (exp_a == 8'h00) ? {1'b0, frac_a} : {1'b1, frac_a};
                sig_b     = (exp_b == 8'h00) ? {1'b0, frac_b} : {1'b1, frac_b};
                exp_eff_a = (exp_a == 8'h00) ? 8'h01 : exp_a;
                exp_eff_b = (exp_b == 8'h00) ? 8'h01 : exp_b;

                /*
                 * Select operand with larger magnitude.
                 */
                if ((exp_eff_a > exp_eff_b) ||
                    ((exp_eff_a == exp_eff_b) && (sig_a >= sig_b))) begin
                    sign_big   = sign_a;
                    sign_small = sign_b;
                    exp_big    = exp_eff_a;
                    exp_small  = exp_eff_b;
                    sig_big    = sig_a;
                    sig_small  = sig_b;
                end else begin
                    sign_big   = sign_b;
                    sign_small = sign_a;
                    exp_big    = exp_eff_b;
                    exp_small  = exp_eff_a;
                    sig_big    = sig_b;
                    sig_small  = sig_a;
                end

                shift_amt  = exp_big - exp_small;
                mant_big   = {sig_big,   3'b000};
                mant_small = shr_jam_27({sig_small, 3'b000}, shift_amt);

                sign_res = sign_big;
                exp_res  = {3'b000, exp_big};

                if (sign_big == sign_small) begin
                    /*
                     * Same sign: add magnitudes.
                     */
                    mant_sum = {1'b0, mant_big} + {1'b0, mant_small};

                    if (mant_sum[27]) begin
                        mant_res    = mant_sum[27:1];
                        mant_res[0] = mant_res[0] | mant_sum[0];
                        exp_res     = exp_res + 11'sd1;
                    end else begin
                        mant_res = mant_sum[26:0];
                    end
                end else begin
                    /*
                     * Opposite signs: subtract smaller magnitude from larger.
                     */
                    mant_res = mant_big - mant_small;

                    if (mant_res == 27'h0000000) begin
                        fp32_add = 32'h00000000;
                    end else begin
                        /*
                         * Normalize left while possible.  Stop at effective
                         * exponent 1 so that subnormal results can be emitted.
                         */
                        for (k = 0; k < 26; k = k + 1) begin
                            if ((mant_res[26] == 1'b0) && (exp_res > 11'sd1)) begin
                                mant_res = mant_res << 1;
                                exp_res  = exp_res - 11'sd1;
                            end
                        end
                    end
                end

                if (!((sign_big != sign_small) && (mant_res == 27'h0000000))) begin
                    /*
                     * Round to nearest, ties to even.
                     */
                    guard_bit  = mant_res[2];
                    round_bit  = mant_res[1];
                    sticky_bit = mant_res[0];
                    mant24     = mant_res[26:3];

                    round_inc = guard_bit & (round_bit | sticky_bit | mant24[0]);
                    rounded   = {1'b0, mant24} + round_inc;

                    if (rounded[24]) begin
                        mant24  = rounded[24:1];
                        exp_res = exp_res + 11'sd1;
                    end else begin
                        mant24 = rounded[23:0];
                    end

                    if (mant24 == 24'h000000) begin
                        fp32_add = 32'h00000000;
                    end else if (exp_res >= 11'sd255) begin
                        fp32_add = {sign_res, 8'hff, 23'h000000};
                    end else if (exp_res <= 11'sd0) begin
                        fp32_add = 32'h00000000;
                    end else if ((exp_res == 11'sd1) && (mant24[23] == 1'b0)) begin
                        /*
                         * Subnormal result.
                         */
                        fp32_add = {sign_res, 8'h00, mant24[22:0]};
                    end else begin
                        fp32_add = {sign_res, exp_res[7:0], mant24[22:0]};
                    end
                end
            end
        end
    endfunction


    integer i;
    reg [31:0] acc;

    always @* begin
        acc = 32'h00000000;

        for (i = 0; i < TAP_CNT; i = i + 1) begin
            acc = fp32_add(acc, products_flat[i*32 +: 32]);
        end
    end

    assign sum_out = acc;

endmodule