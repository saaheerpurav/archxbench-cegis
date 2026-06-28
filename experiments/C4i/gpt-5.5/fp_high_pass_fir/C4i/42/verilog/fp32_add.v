`timescale 1ns/1ps

module fp32_add (
    input  [31:0] a,
    input  [31:0] b,
    output reg [31:0] y
);

    /*
     * Right shift with sticky-bit jam.
     *
     * Input format is 27 bits:
     *   [26:3] significand bits
     *   [2]    guard
     *   [1]    round
     *   [0]    sticky
     *
     * Any nonzero bit shifted out is ORed into bit 0.
     */
    function [26:0] shr_jam_27;
        input [26:0] value;
        input integer shamt;
        reg sticky;
        begin
            if (shamt <= 0) begin
                shr_jam_27 = value;
            end else if (shamt < 27) begin
                sticky = |(value & ((27'h1 << shamt) - 27'h1));
                shr_jam_27 = value >> shamt;
                shr_jam_27[0] = shr_jam_27[0] | sticky;
            end else begin
                shr_jam_27 = 27'h0;
                shr_jam_27[0] = |value;
            end
        end
    endfunction

    wire        sign_a = a[31];
    wire        sign_b = b[31];
    wire [7:0]  exp_a  = a[30:23];
    wire [7:0]  exp_b  = b[30:23];
    wire [22:0] frac_a = a[22:0];
    wire [22:0] frac_b = b[22:0];

    wire a_zero = (exp_a == 8'h00) && (frac_a == 23'h000000);
    wire b_zero = (exp_b == 8'h00) && (frac_b == 23'h000000);

    wire a_inf  = (exp_a == 8'hff) && (frac_a == 23'h000000);
    wire b_inf  = (exp_b == 8'hff) && (frac_b == 23'h000000);

    wire a_nan  = (exp_a == 8'hff) && (frac_a != 23'h000000);
    wire b_nan  = (exp_b == 8'hff) && (frac_b != 23'h000000);

    reg signed [10:0] ea;
    reg signed [10:0] eb;
    reg signed [10:0] e_big;

    reg        sign_big;
    reg        sign_small;
    reg        result_sign;

    reg [23:0] ma24;
    reg [23:0] mb24;

    reg [26:0] ma_ext;
    reg [26:0] mb_ext;
    reg [26:0] big_ext;
    reg [26:0] small_ext;
    reg [26:0] small_shifted;

    reg [27:0] add_sum;
    reg [26:0] mant_ext;
    reg [26:0] diff_ext;

    reg [23:0] mant_main;
    reg        guard_bit;
    reg        round_bit;
    reg        sticky_bit;
    reg        round_inc;
    reg [24:0] rounded;

    reg signed [11:0] exp_work;
    reg [7:0] exp_out;

    integer shift_amt;
    integer norm_count;

    always @* begin
        y = 32'h00000000;

        ea = 11'sd0;
        eb = 11'sd0;
        e_big = 11'sd0;

        sign_big = 1'b0;
        sign_small = 1'b0;
        result_sign = 1'b0;

        ma24 = 24'h000000;
        mb24 = 24'h000000;

        ma_ext = 27'h0000000;
        mb_ext = 27'h0000000;
        big_ext = 27'h0000000;
        small_ext = 27'h0000000;
        small_shifted = 27'h0000000;

        add_sum = 28'h0000000;
        mant_ext = 27'h0000000;
        diff_ext = 27'h0000000;

        mant_main = 24'h000000;
        guard_bit = 1'b0;
        round_bit = 1'b0;
        sticky_bit = 1'b0;
        round_inc = 1'b0;
        rounded = 25'h0000000;

        exp_work = 12'sd0;
        exp_out = 8'h00;

        shift_amt = 0;
        norm_count = 0;

        /*
         * Special cases.
         */
        if (a_nan) begin
            y = {1'b0, 8'hff, 1'b1, frac_a[21:0]};
        end else if (b_nan) begin
            y = {1'b0, 8'hff, 1'b1, frac_b[21:0]};
        end else if (a_inf && b_inf && (sign_a != sign_b)) begin
            y = 32'h7fc00000;
        end else if (a_inf) begin
            y = a;
        end else if (b_inf) begin
            y = b;
        end else if (a_zero && b_zero) begin
            /*
             * For this FIR datapath, prefer deterministic +0.
             */
            y = 32'h00000000;
        end else if (a_zero) begin
            y = b;
        end else if (b_zero) begin
            y = a;
        end else begin
            /*
             * Decode operands.
             *
             * Normal:
             *   value = (-1)^sign * 1.frac * 2^(exp-127)
             *
             * Subnormal:
             *   value = (-1)^sign * 0.frac * 2^(-126)
             */
            if (exp_a == 8'h00) begin
                ea = -11'sd126;
                ma24 = {1'b0, frac_a};
            end else begin
                ea = {3'b000, exp_a} - 11'sd127;
                ma24 = {1'b1, frac_a};
            end

            if (exp_b == 8'h00) begin
                eb = -11'sd126;
                mb24 = {1'b0, frac_b};
            end else begin
                eb = {3'b000, exp_b} - 11'sd127;
                mb24 = {1'b1, frac_b};
            end

            /*
             * Add three low bits for guard/round/sticky.
             */
            ma_ext = {ma24, 3'b000};
            mb_ext = {mb24, 3'b000};

            /*
             * Select operand with larger magnitude.
             * This determines alignment direction and subtraction sign.
             */
            if ((ea > eb) || ((ea == eb) && (ma_ext >= mb_ext))) begin
                e_big = ea;
                big_ext = ma_ext;
                small_ext = mb_ext;
                sign_big = sign_a;
                sign_small = sign_b;
                shift_amt = ea - eb;
            end else begin
                e_big = eb;
                big_ext = mb_ext;
                small_ext = ma_ext;
                sign_big = sign_b;
                sign_small = sign_a;
                shift_amt = eb - ea;
            end

            small_shifted = shr_jam_27(small_ext, shift_amt);

            exp_work = e_big;
            result_sign = sign_big;

            /*
             * Add or subtract significands.
             */
            if (sign_big == sign_small) begin
                add_sum = {1'b0, big_ext} + {1'b0, small_shifted};

                /*
                 * Carry-out means significand is in [2,4), so shift right
                 * one place and increment exponent. Preserve shifted-out bit
                 * through sticky.
                 */
                if (add_sum[27]) begin
                    mant_ext = add_sum[27:1];
                    mant_ext[0] = mant_ext[0] | add_sum[0];
                    exp_work = exp_work + 12'sd1;
                end else begin
                    mant_ext = add_sum[26:0];
                end
            end else begin
                diff_ext = big_ext - small_shifted;
                mant_ext = diff_ext;

                if (mant_ext == 27'h0000000) begin
                    result_sign = 1'b0;
                    exp_work = -12'sd126;
                end else begin
                    /*
                     * Normalize left while possible.
                     *
                     * Stop at exponent -126.  Below that, the value is
                     * represented as a subnormal with hidden bit zero.
                     */
                    norm_count = 0;
                    while ((mant_ext[26] == 1'b0) &&
                           (exp_work > -12'sd126) &&
                           (norm_count < 27)) begin
                        mant_ext = mant_ext << 1;
                        exp_work = exp_work - 12'sd1;
                        norm_count = norm_count + 1;
                    end
                end
            end

            /*
             * Zero after cancellation.
             */
            if (mant_ext == 27'h0000000) begin
                y = 32'h00000000;
            end else begin
                /*
                 * Round to nearest, ties to even.
                 */
                mant_main  = mant_ext[26:3];
                guard_bit  = mant_ext[2];
                round_bit  = mant_ext[1];
                sticky_bit = mant_ext[0];

                round_inc = guard_bit & (round_bit | sticky_bit | mant_main[0]);

                rounded = {1'b0, mant_main} + {24'h000000, round_inc};

                /*
                 * Rounding may overflow the significand.
                 */
                if (rounded[24]) begin
                    mant_main = rounded[24:1];
                    exp_work = exp_work + 12'sd1;
                end else begin
                    mant_main = rounded[23:0];
                end

                /*
                 * Pack result.
                 */
                if ((exp_work + 12'sd127) >= 12'sd255) begin
                    y = {result_sign, 8'hff, 23'h000000};
                end else if (exp_work > -12'sd126) begin
                    exp_out = exp_work[7:0] + 8'd127;
                    y = {result_sign, exp_out, mant_main[22:0]};
                end else if (exp_work == -12'sd126) begin
                    /*
                     * At exponent -126, mantissa with bit 23 set is the
                     * smallest-normal binade; otherwise it is subnormal.
                     */
                    if (mant_main[23]) begin
                        y = {result_sign, 8'h01, mant_main[22:0]};
                    end else begin
                        y = {result_sign, 8'h00, mant_main[22:0]};
                    end
                end else begin
                    y = {result_sign, 31'h00000000};
                end
            end
        end
    end

endmodule