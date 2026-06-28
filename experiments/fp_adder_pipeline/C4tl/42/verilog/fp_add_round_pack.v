`timescale 1ns/1ps

module fp_add_round_pack (
    input         special_in,
    input  [31:0] special_result_in,
    input         sign_in,
    input  [8:0]  exp_in,
    input  [26:0] sig_in,
    input         zero_in,
    output reg [31:0] result
);

    reg        guard_bit;
    reg        round_bit;
    reg        sticky_bit;
    reg        lsb_bit;
    reg        increment;

    reg        normal_pre;
    reg [23:0] sig_main;
    reg [24:0] rounded_ext;
    reg [23:0] rounded_sig;
    reg [8:0]  rounded_exp;

    always @* begin
        /*
         * sig_in layout:
         *   [26:3] : retained 24-bit significand, including hidden bit
         *   [2]    : guard bit
         *   [1]    : round bit
         *   [0]    : sticky bit
         */
        sig_main   = sig_in[26:3];
        guard_bit = sig_in[2];
        round_bit = sig_in[1];
        sticky_bit = sig_in[0];
        lsb_bit   = sig_in[3];

        /*
         * IEEE-754 round-to-nearest-even.
         *
         * Increment when the discarded portion is greater than half an ulp,
         * or exactly half an ulp and the retained LSB is odd.
         */
        increment = guard_bit & (round_bit | sticky_bit | lsb_bit);

        normal_pre = sig_in[26];

        rounded_ext = {1'b0, sig_main} + {24'd0, increment};
        rounded_sig = rounded_ext[23:0];

        /*
         * Normally exp_in already contains the packed exponent value that
         * corresponds to sig_in.  The exp_in == 0 && hidden-bit-set case is
         * treated as a boundary promotion to exponent 1 for robustness.
         */
        if ((exp_in == 9'd0) && normal_pre)
            rounded_exp = 9'd1;
        else
            rounded_exp = exp_in;

        result = 32'd0;

        if (special_in) begin
            result = special_result_in;
        end else if (zero_in || (sig_in == 27'd0)) begin
            /*
             * Canonical exact zero.  This handles cancellation and +/-0
             * additions as +0.0.
             */
            result = 32'h00000000;
        end else begin
            if (normal_pre) begin
                /*
                 * Normal input significand.  Rounding can create a carry into
                 * bit 24, requiring a right shift and exponent increment.
                 */
                if (rounded_ext[24]) begin
                    rounded_sig = rounded_ext[24:1];
                    rounded_exp = rounded_exp + 9'd1;
                end

                /*
                 * Exponent overflow packs to infinity for round-to-nearest-even.
                 */
                if (rounded_exp >= 9'd255) begin
                    result = {sign_in, 8'hFF, 23'd0};
                end else begin
                    result = {sign_in, rounded_exp[7:0], rounded_sig[22:0]};
                end
            end else begin
                /*
                 * Subnormal input significand.  If rounding sets bit 23, the
                 * value has promoted to the minimum normal range and must be
                 * packed with exponent field 1.
                 */
                if (rounded_ext[23]) begin
                    result = {sign_in, 8'd1, rounded_ext[22:0]};
                end else begin
                    result = {sign_in, 8'd0, rounded_ext[22:0]};
                end
            end
        end
    end

endmodule