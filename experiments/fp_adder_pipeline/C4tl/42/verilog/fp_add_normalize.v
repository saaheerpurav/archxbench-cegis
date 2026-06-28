`timescale 1ns/1ps

module fp_add_normalize (
    input         special_in,
    input  [31:0] special_result_in,
    input         sign_in,
    input  [8:0]  exp_in,
    input  [27:0] raw_sum,
    input         zero_in,

    output reg        special_out,
    output reg [31:0] special_result_out,
    output reg        sign_out,
    output reg [8:0]  exp_out,
    output reg [26:0] sig_out,
    output reg        zero_out
);

    integer i;

    reg [8:0]  exp_tmp;
    reg [26:0] sig_tmp;

    always @* begin
        /*
         * Special-case metadata is purely forwarded.  Downstream round/pack
         * logic should give special_out priority over the numeric datapath.
         */
        special_out        = special_in;
        special_result_out = special_result_in;

        sign_out = sign_in;
        exp_out  = exp_in;
        sig_out  = 27'd0;
        zero_out = zero_in;

        exp_tmp = exp_in;
        sig_tmp = 27'd0;

        /*
         * Exact zero from the add/sub stage, or a physically zero raw_sum,
         * is canonicalized to +0.
         */
        if (zero_in || (raw_sum == 28'd0)) begin
            sign_out = 1'b0;
            exp_out  = 9'd0;
            sig_out  = 27'd0;
            zero_out = 1'b1;
        end else begin
            /*
             * Right normalization for addition carry-out.
             *
             * raw_sum is 28 bits:
             *   raw_sum[27]    : carry-out / overflow hidden bit
             *   raw_sum[26:0]  : normal significand with G/R/S bits
             *
             * After shifting right by one, the bit shifted out must be ORed
             * into the sticky bit to preserve inexactness information.
             */
            if (raw_sum[27]) begin
                sig_tmp = raw_sum[27:1];
                sig_tmp[0] = sig_tmp[0] | raw_sum[0];
                exp_tmp = exp_in + 9'd1;
            end else begin
                sig_tmp = raw_sum[26:0];
                exp_tmp = exp_in;
            end

            /*
             * Left normalization for cancellation.
             *
             * Shift left until the hidden bit is restored, but do not reduce
             * the effective exponent below 1.  At exponent 1, a significand
             * with sig_tmp[26] == 0 represents a subnormal-boundary result
             * and is left for the round/pack stage to encode correctly.
             */
            for (i = 0; i < 27; i = i + 1) begin
                if ((sig_tmp != 27'd0) &&
                    (sig_tmp[26] == 1'b0) &&
                    (exp_tmp > 9'd1)) begin
                    sig_tmp = sig_tmp << 1;
                    exp_tmp = exp_tmp - 9'd1;
                end
            end

            if (sig_tmp == 27'd0) begin
                sign_out = 1'b0;
                exp_out  = 9'd0;
                sig_out  = 27'd0;
                zero_out = 1'b1;
            end else begin
                sign_out = sign_in;
                exp_out  = exp_tmp;
                sig_out  = sig_tmp;
                zero_out = 1'b0;
            end
        end
    end

endmodule