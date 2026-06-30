`timescale 1ns/1ps

module fp_normalize_round #(
    parameter integer WIDTH = 32,
    parameter integer EXP_WIDTH = 8,
    parameter integer MANT_WIDTH = WIDTH - EXP_WIDTH - 1
)(
    input raw_sign,
    input raw_zero,
    input [EXP_WIDTH:0] raw_exp,
    input [MANT_WIDTH+4:0] raw_sig,
    input [2:0] rnd_mode,
    input input_denorm,
    output reg [WIDTH-1:0] result,
    output reg [2:0] flags
);
    localparam integer SIG_WIDTH = MANT_WIDTH + 5;
    localparam [EXP_WIDTH:0] MAX_EXP = {1'b0, {EXP_WIDTH{1'b1}}};

    reg [EXP_WIDTH:0] exp_work;
    reg [SIG_WIDTH-1:0] sig_work;
    reg [MANT_WIDTH:0] main_sig;
    reg guard_bit;
    reg round_bit;
    reg sticky_bit;
    reg inexact;
    reg increment;
    reg [MANT_WIDTH+1:0] rounded_sig;
    reg overflow;
    reg underflow;
    reg [MANT_WIDTH-1:0] max_frac;
    integer i;

    always @* begin
        exp_work = raw_exp;
        sig_work = raw_sig;
        flags = 3'b000;
        result = {WIDTH{1'b0}};
        overflow = 1'b0;
        underflow = 1'b0;
        max_frac = {MANT_WIDTH{1'b1}};

        if (raw_zero) begin
            result = {(rnd_mode == 3'b011), {EXP_WIDTH{1'b0}}, {MANT_WIDTH{1'b0}}};
        end else begin
            if (sig_work[MANT_WIDTH+4]) begin
                sticky_bit = sig_work[0] | sig_work[1];
                sig_work = sig_work >> 1;
                sig_work[0] = sticky_bit;
                exp_work = exp_work + 1'b1;
            end else begin
                for (i = 0; i < MANT_WIDTH + 4; i = i + 1) begin
                    if (!sig_work[MANT_WIDTH+3] && (exp_work > 1)) begin
                        sig_work = sig_work << 1;
                        exp_work = exp_work - 1'b1;
                    end
                end
            end

            main_sig = sig_work[MANT_WIDTH+3:3];
            guard_bit = sig_work[2];
            round_bit = sig_work[1];
            sticky_bit = sig_work[0];
            inexact = guard_bit | round_bit | sticky_bit;

            increment = 1'b0;
            case (rnd_mode)
                3'b000: increment = guard_bit & (round_bit | sticky_bit | main_sig[0]);
                3'b001: increment = 1'b0;
                3'b010: increment = !raw_sign & inexact;
                3'b011: increment = raw_sign & inexact;
                default: increment = guard_bit & (round_bit | sticky_bit | main_sig[0]);
            endcase

            rounded_sig = {1'b0, main_sig} + increment;

            if (rounded_sig[MANT_WIDTH+1]) begin
                rounded_sig = rounded_sig >> 1;
                exp_work = exp_work + 1'b1;
            end

            if (exp_work >= MAX_EXP) begin
                overflow = 1'b1;

                case (rnd_mode)
                    3'b001: result = {raw_sign, {EXP_WIDTH{1'b1}}, max_frac};
                    3'b010: result = raw_sign
                        ? {raw_sign, {EXP_WIDTH{1'b1}}, max_frac}
                        : {raw_sign, {EXP_WIDTH{1'b1}}, {MANT_WIDTH{1'b0}}};
                    3'b011: result = raw_sign
                        ? {raw_sign, {EXP_WIDTH{1'b1}}, {MANT_WIDTH{1'b0}}}
                        : {raw_sign, {EXP_WIDTH{1'b1}}, max_frac};
                    default: result = {raw_sign, {EXP_WIDTH{1'b1}}, {MANT_WIDTH{1'b0}}};
                endcase
            end else if (exp_work == 0) begin
                underflow = inexact | (rounded_sig[MANT_WIDTH-1:0] != {MANT_WIDTH{1'b0}});
                result = {raw_sign, {EXP_WIDTH{1'b0}}, rounded_sig[MANT_WIDTH-1:0]};
            end else begin
                result = {raw_sign, exp_work[EXP_WIDTH-1:0], rounded_sig[MANT_WIDTH-1:0]};
            end

            flags[2] = 1'b0;
            flags[1] = overflow;
            flags[0] = input_denorm | underflow;
        end
    end
endmodule