`timescale 1ns/1ps

module fp_multiplier_normalize_round_pack #(
    parameter EXP_WIDTH  = 8,
    parameter MANT_WIDTH = 23,
    parameter WIDTH      = 1 + EXP_WIDTH + MANT_WIDTH
)(
    input  sign,
    input  [2*(MANT_WIDTH+1)-1:0] significand_product,
    input  signed [EXP_WIDTH+2:0] exponent_sum,
    input  [2:0] rnd_mode,
    output reg [WIDTH-1:0] packed_result,
    output reg [2:0] flags
);

    localparam integer SIG_WIDTH    = MANT_WIDTH + 1;
    localparam integer PROD_WIDTH   = 2 * SIG_WIDTH;
    localparam integer NORMAL_POINT = 2 * MANT_WIDTH;
    localparam integer BIAS         = (1 << (EXP_WIDTH-1)) - 1;
    localparam integer MAX_EXP      = (1 << EXP_WIDTH) - 1;

    integer i;
    integer k;
    integer lead_index;
    integer shift_amt;

    reg found;

    reg signed [EXP_WIDTH+5:0] exp_norm;
    reg signed [EXP_WIDTH+5:0] biased_exp;
    reg signed [EXP_WIDTH+5:0] biased_after_round;

    reg [MANT_WIDTH:0]   sig_trunc;
    reg [MANT_WIDTH+1:0] sig_rounded;

    reg guard_bit;
    reg round_bit;
    reg sticky_bit;
    reg inexact;
    reg increment;

    reg [EXP_WIDTH-1:0]  exp_field;
    reg [MANT_WIDTH-1:0] mant_field;

    always @(*) begin
        packed_result      = {WIDTH{1'b0}};
        flags              = 3'b000;

        lead_index         = 0;
        shift_amt          = 0;
        found              = 1'b0;

        exp_norm           = {EXP_WIDTH+6{1'b0}};
        biased_exp         = {EXP_WIDTH+6{1'b0}};
        biased_after_round = {EXP_WIDTH+6{1'b0}};

        sig_trunc          = {MANT_WIDTH+1{1'b0}};
        sig_rounded        = {MANT_WIDTH+2{1'b0}};

        guard_bit          = 1'b0;
        round_bit          = 1'b0;
        sticky_bit         = 1'b0;
        inexact            = 1'b0;
        increment          = 1'b0;

        exp_field          = {EXP_WIDTH{1'b0}};
        mant_field         = {MANT_WIDTH{1'b0}};

        /*
         * Locate the most significant one in the raw significand product.
         * For a normal product of two normalized operands, this will usually
         * be either NORMAL_POINT or NORMAL_POINT + 1.
         */
        for (i = PROD_WIDTH-1; i >= 0; i = i - 1) begin
            if (!found && significand_product[i]) begin
                lead_index = i;
                found      = 1'b1;
            end
        end

        /*
         * Zero product.  This design uses flush-to-zero style handling and
         * reports the condition through the underflow flag bit.
         */
        if (!found) begin
            packed_result = {sign, {EXP_WIDTH{1'b0}}, {MANT_WIDTH{1'b0}}};
            flags         = 3'b001;
        end else begin
            /*
             * Adjust exponent according to where the leading one was found.
             * NORMAL_POINT corresponds to a significand in [1.0, 2.0).
             */
            exp_norm   = exponent_sum + (lead_index - NORMAL_POINT);
            biased_exp = exp_norm + BIAS;

            /*
             * Flush-to-zero underflow.  Subnormal result generation is not
             * supported by this finite-result stage.
             */
            if (biased_exp <= 0) begin
                packed_result = {sign, {EXP_WIDTH{1'b0}}, {MANT_WIDTH{1'b0}}};
                flags         = 3'b001;
            end

            /*
             * Overflow before rounding.
             */
            else if (biased_exp >= MAX_EXP) begin
                packed_result = {sign, {EXP_WIDTH{1'b1}}, {MANT_WIDTH{1'b0}}};
                flags         = 3'b010;
            end else begin
                /*
                 * Shift so that the leading one lands in sig_trunc[MANT_WIDTH].
                 * sig_trunc contains the hidden bit plus MANT_WIDTH fraction bits.
                 */
                shift_amt = lead_index - MANT_WIDTH;

                if (shift_amt >= 0) begin
                    sig_trunc = significand_product >> shift_amt;
                end else begin
                    sig_trunc = significand_product << (-shift_amt);
                end

                /*
                 * Guard, round, sticky are taken from the bits discarded by the
                 * right shift.  If normalization required a left shift, no low
                 * precision bits were discarded.
                 */
                if (shift_amt >= 1)
                    guard_bit = significand_product[shift_amt-1];
                else
                    guard_bit = 1'b0;

                if (shift_amt >= 2)
                    round_bit = significand_product[shift_amt-2];
                else
                    round_bit = 1'b0;

                sticky_bit = 1'b0;
                if (shift_amt >= 3) begin
                    for (k = 0; k <= shift_amt-3; k = k + 1) begin
                        sticky_bit = sticky_bit | significand_product[k];
                    end
                end

                inexact = guard_bit | round_bit | sticky_bit;

                /*
                 * Rounding modes:
                 *   000 : round to nearest, ties to even
                 *   001 : round toward zero
                 *   010 : round toward +infinity
                 *   011 : round toward -infinity
                 *   100 : round using guard bit / half-up style
                 */
                case (rnd_mode)
                    3'b000: begin
                        increment = guard_bit &&
                                    (round_bit || sticky_bit || sig_trunc[0]);
                    end

                    3'b001: begin
                        increment = 1'b0;
                    end

                    3'b010: begin
                        increment = (!sign) && inexact;
                    end

                    3'b011: begin
                        increment = sign && inexact;
                    end

                    3'b100: begin
                        increment = guard_bit;
                    end

                    default: begin
                        increment = guard_bit &&
                                    (round_bit || sticky_bit || sig_trunc[0]);
                    end
                endcase

                sig_rounded = {1'b0, sig_trunc} + increment;

                /*
                 * Rounding can produce 10.000..., requiring a one-bit right
                 * normalization and exponent increment.
                 */
                if (sig_rounded[MANT_WIDTH+1]) begin
                    biased_after_round = biased_exp + 1;
                    mant_field         = sig_rounded[MANT_WIDTH:1];
                end else begin
                    biased_after_round = biased_exp;
                    mant_field         = sig_rounded[MANT_WIDTH-1:0];
                end

                /*
                 * Overflow after rounding.
                 */
                if (biased_after_round >= MAX_EXP) begin
                    packed_result = {sign, {EXP_WIDTH{1'b1}}, {MANT_WIDTH{1'b0}}};
                    flags         = 3'b010;
                end else begin
                    exp_field     = biased_after_round[EXP_WIDTH-1:0];
                    packed_result = {sign, exp_field, mant_field};
                    flags         = 3'b000;
                end
            end
        end
    end

endmodule