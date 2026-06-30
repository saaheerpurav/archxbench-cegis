`timescale 1ns/1ps

module fp_normalize_round #(
    parameter EXP_WIDTH  = 8,
    parameter MANT_WIDTH = 23,
    parameter WIDTH      = 1 + EXP_WIDTH + MANT_WIDTH,
    parameter SIG_WIDTH  = MANT_WIDTH + 1,
    parameter PROD_WIDTH = 2 * SIG_WIDTH
)(
    input result_sign,
    input signed [EXP_WIDTH+2:0] exp_sum,
    input [PROD_WIDTH-1:0] sig_product,
    input [2:0] rnd_mode,
    output reg [WIDTH-1:0] result,
    output reg [2:0] exception_flags
);

    localparam integer BIAS    = (1 << (EXP_WIDTH - 1)) - 1;
    localparam integer MAX_EXP = (1 << EXP_WIDTH) - 1;

    reg [PROD_WIDTH-1:0] norm_product;
    reg signed [EXP_WIDTH+3:0] norm_exp;
    reg signed [EXP_WIDTH+3:0] biased_exp;

    reg [SIG_WIDTH-1:0] sig_main;
    reg guard_bit;
    reg round_bit;
    reg sticky_bit;
    reg increment;
    reg [SIG_WIDTH:0] rounded_sig;
    reg signed [EXP_WIDTH+3:0] rounded_exp;

    reg [EXP_WIDTH-1:0] final_exp;
    reg [MANT_WIDTH-1:0] final_mant;

    reg inexact;
    reg overflow_to_inf;

    always @(*) begin
        result = {WIDTH{1'b0}};
        exception_flags = 3'b000;

        norm_product = {PROD_WIDTH{1'b0}};
        norm_exp = {EXP_WIDTH+4{1'b0}};
        biased_exp = {EXP_WIDTH+4{1'b0}};
        sig_main = {SIG_WIDTH{1'b0}};
        guard_bit = 1'b0;
        round_bit = 1'b0;
        sticky_bit = 1'b0;
        increment = 1'b0;
        rounded_sig = {SIG_WIDTH+1{1'b0}};
        rounded_exp = {EXP_WIDTH+4{1'b0}};
        final_exp = {EXP_WIDTH{1'b0}};
        final_mant = {MANT_WIDTH{1'b0}};
        inexact = 1'b0;
        overflow_to_inf = 1'b1;

        if (sig_product == {PROD_WIDTH{1'b0}}) begin
            result = {result_sign, {EXP_WIDTH{1'b0}}, {MANT_WIDTH{1'b0}}};
            exception_flags = 3'b001;
        end else begin
            if (sig_product[PROD_WIDTH-1]) begin
                norm_product = sig_product;
                norm_exp = exp_sum + 1'b1;
            end else begin
                norm_product = sig_product << 1;
                norm_exp = exp_sum;
            end

            sig_main = norm_product[PROD_WIDTH-1 -: SIG_WIDTH];
            guard_bit = norm_product[PROD_WIDTH-SIG_WIDTH-1];
            round_bit = norm_product[PROD_WIDTH-SIG_WIDTH-2];
            sticky_bit = |norm_product[PROD_WIDTH-SIG_WIDTH-3:0];
            inexact = guard_bit | round_bit | sticky_bit;

            case (rnd_mode)
                3'b000: increment = guard_bit & (round_bit | sticky_bit | sig_main[0]);
                3'b001: increment = 1'b0;
                3'b010: increment = result_sign & inexact;
                3'b011: increment = ~result_sign & inexact;
                default: increment = guard_bit & (round_bit | sticky_bit | sig_main[0]);
            endcase

            rounded_sig = {1'b0, sig_main} + increment;
            rounded_exp = norm_exp;

            if (rounded_sig[SIG_WIDTH]) begin
                rounded_sig = rounded_sig >> 1;
                rounded_exp = rounded_exp + 1'b1;
            end

            biased_exp = rounded_exp + BIAS;

            if (biased_exp >= MAX_EXP) begin
                case (rnd_mode)
                    3'b001: overflow_to_inf = 1'b0;
                    3'b010: overflow_to_inf = result_sign;
                    3'b011: overflow_to_inf = ~result_sign;
                    default: overflow_to_inf = 1'b1;
                endcase

                if (overflow_to_inf) begin
                    result = {result_sign, {EXP_WIDTH{1'b1}}, {MANT_WIDTH{1'b0}}};
                end else begin
                    result = {
                        result_sign,
                        {EXP_WIDTH{1'b1}} - {{(EXP_WIDTH-1){1'b0}}, 1'b1},
                        {MANT_WIDTH{1'b1}}
                    };
                end

                exception_flags = 3'b010;
            end else if (biased_exp <= 0) begin
                result = {result_sign, {EXP_WIDTH{1'b0}}, {MANT_WIDTH{1'b0}}};
                exception_flags = 3'b001;
            end else begin
                final_exp = biased_exp[EXP_WIDTH-1:0];
                final_mant = rounded_sig[MANT_WIDTH-1:0];
                result = {result_sign, final_exp, final_mant};
                exception_flags = 3'b000;
            end
        end
    end

endmodule