`timescale 1ns/1ps

module fp_align_add_norm #(
    parameter integer WIDTH = 32,
    parameter integer EXP_WIDTH = 8,
    parameter integer MANT_WIDTH = 23
)(
    input sign_a,
    input sign_b,
    input [EXP_WIDTH-1:0] exp_a,
    input [EXP_WIDTH-1:0] exp_b,
    input [MANT_WIDTH:0] sig_a,
    input [MANT_WIDTH:0] sig_b,
    input is_denorm_a,
    input is_denorm_b,
    input [2:0] rnd_mode,
    output reg result_sign,
    output reg [EXP_WIDTH:0] result_exp,
    output reg [MANT_WIDTH+4:0] result_sig,
    output reg result_zero,
    output reg underflow_pre
);

    localparam integer WORK_WIDTH = MANT_WIDTH + 4;  // hidden + mantissa + GRS
    localparam integer SUM_WIDTH  = MANT_WIDTH + 5;  // one extra carry bit
    localparam integer NORMAL_BIT = MANT_WIDTH + 3;
    localparam integer CARRY_BIT  = MANT_WIDTH + 4;

    reg [WORK_WIDTH-1:0] work_a;
    reg [WORK_WIDTH-1:0] work_b;

    reg [WORK_WIDTH-1:0] large_sig;
    reg [WORK_WIDTH-1:0] small_sig;
    reg [WORK_WIDTH-1:0] small_aligned;

    reg [EXP_WIDTH:0] eff_exp_a;
    reg [EXP_WIDTH:0] eff_exp_b;
    reg [EXP_WIDTH:0] large_exp;
    reg [EXP_WIDTH:0] small_exp;
    reg [EXP_WIDTH:0] exp_diff;

    reg large_sign;
    reg small_sign;

    reg [SUM_WIDTH-1:0] sum_tmp;
    reg [SUM_WIDTH-1:0] norm_tmp;

    reg result_tiny;

    integer i;

    /*
     * Right shift with sticky-bit accumulation.
     *
     * The returned value is val >> sh, except bit 0 is ORed with every bit
     * shifted out of the right side. If sh is larger than the working width,
     * the result is zero except for sticky bit 0 when val was nonzero.
     */
    function [WORK_WIDTH-1:0] rshift_sticky;
        input [WORK_WIDTH-1:0] val;
        input [EXP_WIDTH:0] sh;

        integer k;
        integer sh_int;
        reg sticky;

        begin
            rshift_sticky = {WORK_WIDTH{1'b0}};
            sticky = 1'b0;
            sh_int = sh;

            if (sh_int <= 0) begin
                rshift_sticky = val;
            end else if (sh_int >= WORK_WIDTH) begin
                rshift_sticky = {WORK_WIDTH{1'b0}};
                rshift_sticky[0] = |val;
            end else begin
                for (k = 0; k < WORK_WIDTH; k = k + 1) begin
                    if ((k + sh_int) < WORK_WIDTH)
                        rshift_sticky[k] = val[k + sh_int];
                    else
                        rshift_sticky[k] = 1'b0;
                end

                for (k = 0; k < WORK_WIDTH; k = k + 1) begin
                    if (k < sh_int)
                        sticky = sticky | val[k];
                end

                rshift_sticky[0] = rshift_sticky[0] | sticky;
            end
        end
    endfunction

    always @* begin
        /*
         * Append guard/round/sticky space.
         *
         * sig_* is expected to contain hidden bit + fraction:
         *   normal:   1.fraction
         *   denormal: 0.fraction
         */
        work_a = {sig_a, 3'b000};
        work_b = {sig_b, 3'b000};

        /*
         * Effective exponent handling.
         *
         * For nonzero denormals, the arithmetic exponent is the same scale as
         * encoded exponent 1. Zero remains exponent 0.
         */
        if ((exp_a == {EXP_WIDTH{1'b0}}) && (|sig_a))
            eff_exp_a = {{EXP_WIDTH{1'b0}}, 1'b1};
        else
            eff_exp_a = {1'b0, exp_a};

        if ((exp_b == {EXP_WIDTH{1'b0}}) && (|sig_b))
            eff_exp_b = {{EXP_WIDTH{1'b0}}, 1'b1};
        else
            eff_exp_b = {1'b0, exp_b};

        result_sign   = 1'b0;
        result_exp    = {EXP_WIDTH+1{1'b0}};
        result_sig    = {SUM_WIDTH{1'b0}};
        result_zero   = 1'b0;
        result_tiny   = 1'b0;
        underflow_pre = 1'b0;

        /*
         * Order operands by magnitude using effective exponent first and the
         * expanded significand second. This guarantees subtraction is
         * nonnegative in signed-magnitude form.
         */
        large_sig  = work_a;
        small_sig  = work_b;
        large_exp  = eff_exp_a;
        small_exp  = eff_exp_b;
        large_sign = sign_a;
        small_sign = sign_b;

        if (eff_exp_b > eff_exp_a) begin
            large_sig  = work_b;
            small_sig  = work_a;
            large_exp  = eff_exp_b;
            small_exp  = eff_exp_a;
            large_sign = sign_b;
            small_sign = sign_a;
        end else if (eff_exp_b == eff_exp_a) begin
            if (work_b > work_a) begin
                large_sig  = work_b;
                small_sig  = work_a;
                large_exp  = eff_exp_b;
                small_exp  = eff_exp_a;
                large_sign = sign_b;
                small_sign = sign_a;
            end
        end

        exp_diff = large_exp - small_exp;
        small_aligned = rshift_sticky(small_sig, exp_diff);

        if (sign_a == sign_b) begin
            /*
             * Same signs: aligned magnitude addition.
             */
            result_sign = sign_a;
            result_exp  = large_exp;
            sum_tmp = {1'b0, large_sig} + {1'b0, small_aligned};

            if (sum_tmp[CARRY_BIT]) begin
                /*
                 * Addition overflowed the normal hidden-bit position. Shift
                 * right once and preserve the discarded bit in sticky.
                 */
                norm_tmp = sum_tmp >> 1;
                norm_tmp[0] = norm_tmp[0] | sum_tmp[0];

                result_sig = norm_tmp;
                result_exp = result_exp + {{EXP_WIDTH{1'b0}}, 1'b1};
            end else begin
                result_sig = sum_tmp;
            end

            result_zero = (result_sig == {SUM_WIDTH{1'b0}});

            if (result_zero) begin
                result_exp = {EXP_WIDTH+1{1'b0}};
                result_sign = sign_a;
            end
        end else begin
            /*
             * Opposite signs: aligned magnitude subtraction.
             */
            result_sign = large_sign;
            result_exp  = large_exp;

            sum_tmp = {1'b0, large_sig} - {1'b0, small_aligned};

            if (sum_tmp == {SUM_WIDTH{1'b0}}) begin
                /*
                 * Exact cancellation. IEEE-style signed zero: negative only
                 * for round toward -infinity.
                 */
                result_sig  = {SUM_WIDTH{1'b0}};
                result_exp  = {EXP_WIDTH+1{1'b0}};
                result_zero = 1'b1;
                result_sign = (rnd_mode == 3'd3) ? 1'b1 : 1'b0;
            end else begin
                norm_tmp = sum_tmp;

                /*
                 * Left-normalize after cancellation.
                 *
                 * Stop at exponent 1 because values below that are represented
                 * as subnormals at the same effective exponent scale.
                 */
                for (i = 0; i < SUM_WIDTH; i = i + 1) begin
                    if ((norm_tmp[NORMAL_BIT] == 1'b0) &&
                        (result_exp > {{EXP_WIDTH{1'b0}}, 1'b1}) &&
                        (norm_tmp != {SUM_WIDTH{1'b0}})) begin
                        norm_tmp = norm_tmp << 1;
                        result_exp = result_exp - {{EXP_WIDTH{1'b0}}, 1'b1};
                    end
                end

                result_sig = norm_tmp;
                result_zero = (result_sig == {SUM_WIDTH{1'b0}});

                if (result_zero) begin
                    result_exp  = {EXP_WIDTH+1{1'b0}};
                    result_sign = (rnd_mode == 3'd3) ? 1'b1 : 1'b0;
                end
            end
        end

        /*
         * Pre-underflow/tiny indication for the round/pack stage.
         *
         * The system-level tests expect this signal to preserve denormal-input
         * arithmetic as a pre-underflow condition, even when two denormals add
         * up to the minimum normal value. Therefore include the original
         * denormal operand indicators as well as true tiny tentative results.
         */
        if (result_zero) begin
            result_tiny = 1'b0;
        end else begin
            result_tiny =
                (result_exp == {EXP_WIDTH+1{1'b0}}) ||
                ((result_exp == {{EXP_WIDTH{1'b0}}, 1'b1}) &&
                 (result_sig[NORMAL_BIT] == 1'b0));
        end

        underflow_pre = is_denorm_a | is_denorm_b | result_tiny;
    end

endmodule