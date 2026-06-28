`timescale 1ns/1ps

module fp32_add (
    input  [31:0] a,
    input  [31:0] b,
    output [31:0] result
);

    real ar;
    real br;
    real rr;
    reg [31:0] result_r;

    assign result = result_r;

    always @* begin
        /*
         * Handle IEEE special values explicitly.  Verilog real does not have
         * portable IEEE NaN/Inf behavior, so avoid converting those through
         * real arithmetic.
         */
        if (is_nan(a) || is_nan(b)) begin
            result_r = 32'h7fc00000;
        end else if (is_inf(a) && is_inf(b)) begin
            if (a[31] != b[31])
                result_r = 32'h7fc00000;
            else
                result_r = {a[31], 8'hff, 23'h000000};
        end else if (is_inf(a)) begin
            result_r = {a[31], 8'hff, 23'h000000};
        end else if (is_inf(b)) begin
            result_r = {b[31], 8'hff, 23'h000000};
        end else begin
            ar = fp32_to_real(a);
            br = fp32_to_real(b);
            rr = ar + br;
            result_r = real_to_fp32(rr);
        end
    end

    function is_nan;
        input [31:0] x;
        begin
            is_nan = (x[30:23] == 8'hff) && (x[22:0] != 23'h000000);
        end
    endfunction

    function is_inf;
        input [31:0] x;
        begin
            is_inf = (x[30:23] == 8'hff) && (x[22:0] == 23'h000000);
        end
    endfunction

    function real pow2_real;
        input integer e;
        integer k;
        real r;
        begin
            r = 1.0;

            if (e >= 0) begin
                for (k = 0; k < e; k = k + 1)
                    r = r * 2.0;
            end else begin
                for (k = 0; k < -e; k = k + 1)
                    r = r / 2.0;
            end

            pow2_real = r;
        end
    endfunction

    function integer round_nearest_even;
        input real x;
        integer base;
        real frac;
        begin
            /*
             * x is assumed non-negative and small enough to fit in integer.
             * Verilog integer conversion truncates toward zero.
             */
            base = x;
            frac = x - base;

            if (frac > 0.5) begin
                round_nearest_even = base + 1;
            end else if (frac < 0.5) begin
                round_nearest_even = base;
            end else begin
                if (base[0])
                    round_nearest_even = base + 1;
                else
                    round_nearest_even = base;
            end
        end
    endfunction

    function real fp32_to_real;
        input [31:0] x;

        reg sign_bit;
        integer exp_field;
        integer frac_field;
        real mant;
        real val;

        begin
            sign_bit   = x[31];
            exp_field  = x[30:23];
            frac_field = x[22:0];

            if (exp_field == 0) begin
                if (frac_field == 0) begin
                    val = 0.0;
                end else begin
                    /*
                     * Subnormal:
                     * value = (-1)^sign * 0.frac * 2^-126
                     */
                    mant = frac_field / 8388608.0;
                    val  = mant * pow2_real(-126);
                end
            end else begin
                /*
                 * Normal finite:
                 * value = (-1)^sign * 1.frac * 2^(exp - 127)
                 */
                mant = 1.0 + (frac_field / 8388608.0);
                val  = mant * pow2_real(exp_field - 127);
            end

            if (sign_bit)
                fp32_to_real = -val;
            else
                fp32_to_real = val;
        end
    endfunction

    function [31:0] real_to_fp32;
        input real v;

        reg sign_bit;
        real av;
        real norm;
        real scaled;
        integer exp_unbiased;
        integer exp_field;
        integer frac_int;

        begin
            if (v == 0.0) begin
                /*
                 * For this adder model, exact zero/cancellation returns +0.
                 */
                real_to_fp32 = 32'h00000000;
            end else begin
                sign_bit = (v < 0.0) ? 1'b1 : 1'b0;
                av = sign_bit ? -v : v;

                norm = av;
                exp_unbiased = 0;

                while (norm >= 2.0) begin
                    norm = norm / 2.0;
                    exp_unbiased = exp_unbiased + 1;
                end

                while (norm < 1.0) begin
                    norm = norm * 2.0;
                    exp_unbiased = exp_unbiased - 1;
                end

                exp_field = exp_unbiased + 127;

                if (exp_field <= 0) begin
                    /*
                     * Subnormal or underflow.
                     * Subnormal encoding:
                     *   frac = round(av * 2^149)
                     */
                    scaled = av * pow2_real(149);
                    frac_int = round_nearest_even(scaled);

                    if (frac_int <= 0) begin
                        real_to_fp32 = {sign_bit, 31'h00000000};
                    end else if (frac_int >= 8388608) begin
                        /*
                         * Rounded up from largest subnormal range into the
                         * minimum normal value.
                         */
                        real_to_fp32 = {sign_bit, 8'h01, 23'h000000};
                    end else begin
                        real_to_fp32 = {sign_bit, 8'h00, frac_int[22:0]};
                    end
                end else begin
                    /*
                     * Normal number.
                     * norm is in [1.0, 2.0), so encode fraction bits from
                     * the fractional part after removing the hidden one.
                     */
                    scaled = (norm - 1.0) * 8388608.0;
                    frac_int = round_nearest_even(scaled);

                    if (frac_int >= 8388608) begin
                        /*
                         * Fraction rounded from 1.111... to 10.000...
                         */
                        frac_int = 0;
                        exp_field = exp_field + 1;
                    end

                    if (exp_field >= 255) begin
                        real_to_fp32 = {sign_bit, 8'hff, 23'h000000};
                    end else begin
                        real_to_fp32 = {sign_bit, exp_field[7:0], frac_int[22:0]};
                    end
                end
            end
        end
    endfunction

endmodule