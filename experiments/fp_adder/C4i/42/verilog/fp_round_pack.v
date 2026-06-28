`timescale 1ns/1ps

module fp_round_pack #(
    parameter integer WIDTH = 32,
    parameter integer EXP_WIDTH = 8,
    parameter integer MANT_WIDTH = 23
)(
    input result_sign,
    input [EXP_WIDTH:0] result_exp,
    input [MANT_WIDTH+4:0] result_sig,
    input result_zero,
    input underflow_pre,
    input [2:0] rnd_mode,
    output reg [WIDTH-1:0] packed_result,
    output reg [2:0] flags
);

    localparam integer NORMAL_BIT = MANT_WIDTH + 3;

    localparam [EXP_WIDTH:0] EXP_ZERO_EXT = {(EXP_WIDTH+1){1'b0}};
    localparam [EXP_WIDTH:0] EXP_ONE_EXT  = {{EXP_WIDTH{1'b0}}, 1'b1};
    localparam [EXP_WIDTH:0] EXP_INF_EXT  = {1'b0, {EXP_WIDTH{1'b1}}};

    localparam [EXP_WIDTH-1:0] EXP_ZERO_FIELD = {EXP_WIDTH{1'b0}};
    localparam [EXP_WIDTH-1:0] EXP_ONE_FIELD  = {{(EXP_WIDTH-1){1'b0}}, 1'b1};
    localparam [EXP_WIDTH-1:0] EXP_INF_FIELD  = {EXP_WIDTH{1'b1}};
    localparam [EXP_WIDTH-1:0] EXP_MAX_FINITE_FIELD =
        {EXP_WIDTH{1'b1}} - {{(EXP_WIDTH-1){1'b0}}, 1'b1};

    reg [MANT_WIDTH:0] main_sig;
    reg guard_bit;
    reg round_bit;
    reg sticky_bit;
    reg inexact;
    reg increment;

    reg [MANT_WIDTH+1:0] rounded_sig;
    reg [EXP_WIDTH:0] exp_tmp;

    reg [EXP_WIDTH-1:0] exp_field;
    reg [MANT_WIDTH-1:0] frac_field;

    reg overflow_to_inf;
    reg underflow_flag;

    always @* begin
        packed_result = {WIDTH{1'b0}};
        flags         = 3'b000;

        main_sig      = {(MANT_WIDTH+1){1'b0}};
        guard_bit     = 1'b0;
        round_bit     = 1'b0;
        sticky_bit    = 1'b0;
        inexact       = 1'b0;
        increment     = 1'b0;
        rounded_sig   = {(MANT_WIDTH+2){1'b0}};
        exp_tmp       = result_exp;

        exp_field     = EXP_ZERO_FIELD;
        frac_field    = {MANT_WIDTH{1'b0}};

        overflow_to_inf = 1'b1;
        underflow_flag  = 1'b0;

        if (result_zero) begin
            packed_result = {result_sign, {(WIDTH-1){1'b0}}};
            flags         = 3'b000;
        end else begin
            /*
             * The normal expected layout is:
             *   result_sig[MANT_WIDTH+3:3] = hidden bit + mantissa
             *   result_sig[2]              = guard
             *   result_sig[1]              = round
             *   result_sig[0]              = sticky
             *
             * result_sig[MANT_WIDTH+4] is an extra carry bit.  It should
             * normally already be cleared by the normalize stage, but handling
             * it here makes this final stage tolerant of a one-bit carry.
             */
            if (result_sig[MANT_WIDTH+4]) begin
                main_sig   = result_sig[MANT_WIDTH+4:4];
                guard_bit  = result_sig[3];
                round_bit  = result_sig[2];
                sticky_bit = result_sig[1] | result_sig[0];
                exp_tmp    = result_exp + EXP_ONE_EXT;
            end else begin
                main_sig   = result_sig[NORMAL_BIT:3];
                guard_bit  = result_sig[2];
                round_bit  = result_sig[1];
                sticky_bit = result_sig[0];
                exp_tmp    = result_exp;
            end

            inexact = guard_bit | round_bit | sticky_bit;

            case (rnd_mode)
                3'd0: begin
                    /* Round to nearest, ties to even. */
                    increment = guard_bit & (round_bit | sticky_bit | main_sig[0]);
                end

                3'd1: begin
                    /* Round toward zero. */
                    increment = 1'b0;
                end

                3'd2: begin
                    /* Round toward +infinity. */
                    increment = (~result_sign) & inexact;
                end

                3'd3: begin
                    /* Round toward -infinity. */
                    increment = result_sign & inexact;
                end

                default: begin
                    increment = guard_bit & (round_bit | sticky_bit | main_sig[0]);
                end
            endcase

            rounded_sig = {1'b0, main_sig} +
                          {{(MANT_WIDTH+1){1'b0}}, increment};

            if (rounded_sig[MANT_WIDTH+1]) begin
                main_sig = rounded_sig[MANT_WIDTH+1:1];
                exp_tmp  = exp_tmp + EXP_ONE_EXT;
            end else begin
                main_sig = rounded_sig[MANT_WIDTH:0];
            end

            if (exp_tmp >= EXP_INF_EXT) begin
                case (rnd_mode)
                    3'd1: overflow_to_inf = 1'b0;          /* toward zero */
                    3'd2: overflow_to_inf = ~result_sign;  /* toward +inf */
                    3'd3: overflow_to_inf =  result_sign;  /* toward -inf */
                    default: overflow_to_inf = 1'b1;       /* nearest */
                endcase

                if (overflow_to_inf) begin
                    packed_result = {
                        result_sign,
                        EXP_INF_FIELD,
                        {MANT_WIDTH{1'b0}}
                    };
                end else begin
                    packed_result = {
                        result_sign,
                        EXP_MAX_FINITE_FIELD,
                        {MANT_WIDTH{1'b1}}
                    };
                end

                flags = 3'b010;
            end else begin
                /*
                 * Subnormal handling:
                 *
                 * Many normalize stages keep exp_tmp at 1 for subnormal-scale
                 * results and indicate subnormality by clearing the hidden bit.
                 * Therefore:
                 *   exp_tmp == 1 && hidden == 0 => packed exponent 0.
                 *
                 * Also tolerate exp_tmp == 0.  If rounding made the hidden bit
                 * become 1, the value has rounded up into the minimum normal.
                 */
                if (exp_tmp == EXP_ZERO_EXT) begin
                    if (main_sig[MANT_WIDTH]) begin
                        exp_field  = EXP_ONE_FIELD;
                        frac_field = main_sig[MANT_WIDTH-1:0];
                    end else begin
                        exp_field  = EXP_ZERO_FIELD;
                        frac_field = main_sig[MANT_WIDTH-1:0];
                    end
                end else if ((exp_tmp == EXP_ONE_EXT) &&
                             (main_sig[MANT_WIDTH] == 1'b0)) begin
                    exp_field  = EXP_ZERO_FIELD;
                    frac_field = main_sig[MANT_WIDTH-1:0];
                end else begin
                    exp_field  = exp_tmp[EXP_WIDTH-1:0];
                    frac_field = main_sig[MANT_WIDTH-1:0];
                end

                packed_result = {result_sign, exp_field, frac_field};

                underflow_flag =
                    underflow_pre |
                    ((exp_field == EXP_ZERO_FIELD) & inexact);

                flags = underflow_flag ? 3'b001 : 3'b000;
            end
        end
    end

endmodule