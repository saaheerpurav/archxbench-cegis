`timescale 1ns/1ps

module fp_add_core #(
    parameter WIDTH = 32,
    parameter EXP_WIDTH = 8,
    parameter MANT_WIDTH = 23
)(
    input sign_a,
    input sign_b,
    input [EXP_WIDTH-1:0] exp_a,
    input [EXP_WIDTH-1:0] exp_b,
    input [MANT_WIDTH-1:0] mant_a,
    input [MANT_WIDTH-1:0] mant_b,
    input a_denorm,
    input b_denorm,
    input [2:0] rnd_mode,
    output reg [WIDTH-1:0] sum,
    output reg [2:0] exception_flags
);

    localparam SIG_WIDTH = MANT_WIDTH + 1;
    localparam EXT_WIDTH = MANT_WIDTH + 4;
    localparam [EXP_WIDTH-1:0] EXP_MAX = {EXP_WIDTH{1'b1}};

    reg [SIG_WIDTH-1:0] sig_a;
    reg [SIG_WIDTH-1:0] sig_b;
    reg [EXP_WIDTH:0] eff_exp_a;
    reg [EXP_WIDTH:0] eff_exp_b;
    reg [EXP_WIDTH:0] big_exp;
    reg [EXP_WIDTH:0] exp_res;

    reg [EXT_WIDTH-1:0] ext_a;
    reg [EXT_WIDTH-1:0] ext_b;
    reg [EXT_WIDTH:0] ext_sum;
    reg [EXT_WIDTH-1:0] ext_res;

    reg result_sign;
    reg guard_bit;
    reg round_bit;
    reg sticky_bit;
    reg lsb_bit;
    reg inc;

    reg [SIG_WIDTH:0] rounded_full;
    reg [SIG_WIDTH-1:0] rounded_sig;

    integer diff;
    integer i;

    function [EXT_WIDTH-1:0] shr_jam;
        input [EXT_WIDTH-1:0] value;
        input integer shamt;
        reg sticky;
        integer j;
        begin
            if (shamt <= 0) begin
                shr_jam = value;
            end else if (shamt >= EXT_WIDTH) begin
                shr_jam = {{(EXT_WIDTH-1){1'b0}}, |value};
            end else begin
                sticky = 1'b0;
                for (j = 0; j < shamt; j = j + 1)
                    sticky = sticky | value[j];

                shr_jam = value >> shamt;
                shr_jam[0] = shr_jam[0] | sticky;
            end
        end
    endfunction

    always @(*) begin
        sig_a = (exp_a == 0) ? {1'b0, mant_a} : {1'b1, mant_a};
        sig_b = (exp_b == 0) ? {1'b0, mant_b} : {1'b1, mant_b};

        eff_exp_a = (exp_a == 0) ? {{EXP_WIDTH{1'b0}}, 1'b1} : {1'b0, exp_a};
        eff_exp_b = (exp_b == 0) ? {{EXP_WIDTH{1'b0}}, 1'b1} : {1'b0, exp_b};

        ext_a = {sig_a, 3'b000};
        ext_b = {sig_b, 3'b000};

        if (eff_exp_a >= eff_exp_b) begin
            diff = eff_exp_a - eff_exp_b;
            ext_b = shr_jam(ext_b, diff);
            big_exp = eff_exp_a;
        end else begin
            diff = eff_exp_b - eff_exp_a;
            ext_a = shr_jam(ext_a, diff);
            big_exp = eff_exp_b;
        end

        if (sign_a == sign_b) begin
            ext_sum = {1'b0, ext_a} + {1'b0, ext_b};
            result_sign = sign_a;
        end else if (ext_a >= ext_b) begin
            ext_sum = {1'b0, ext_a} - {1'b0, ext_b};
            result_sign = sign_a;
        end else begin
            ext_sum = {1'b0, ext_b} - {1'b0, ext_a};
            result_sign = sign_b;
        end

        exp_res = big_exp;
        ext_res = ext_sum[EXT_WIDTH-1:0];

        guard_bit = 1'b0;
        round_bit = 1'b0;
        sticky_bit = 1'b0;
        lsb_bit = 1'b0;
        inc = 1'b0;
        rounded_full = {SIG_WIDTH+1{1'b0}};
        rounded_sig = {SIG_WIDTH{1'b0}};

        if (ext_sum == {EXT_WIDTH+1{1'b0}}) begin
            sum = {(rnd_mode == 3'b011), {EXP_WIDTH{1'b0}}, {MANT_WIDTH{1'b0}}};
            exception_flags = 3'b000;
        end else begin
            if ((sign_a == sign_b) && ext_sum[EXT_WIDTH]) begin
                ext_res = ext_sum[EXT_WIDTH:1];
                ext_res[0] = ext_res[0] | ext_sum[0];
                exp_res = big_exp + 1'b1;
            end else begin
                for (i = 0; i < EXT_WIDTH; i = i + 1) begin
                    if ((ext_res[EXT_WIDTH-1] == 1'b0) && (exp_res > 1)) begin
                        ext_res = ext_res << 1;
                        exp_res = exp_res - 1'b1;
                    end
                end
            end

            guard_bit = ext_res[2];
            round_bit = ext_res[1];
            sticky_bit = ext_res[0];
            lsb_bit = ext_res[3];

            case (rnd_mode)
                3'b000: inc = guard_bit && (round_bit || sticky_bit || lsb_bit);
                3'b001: inc = 1'b0;
                3'b010: inc = (!result_sign) && (guard_bit || round_bit || sticky_bit);
                3'b011: inc = result_sign && (guard_bit || round_bit || sticky_bit);
                default: inc = guard_bit && (round_bit || sticky_bit || lsb_bit);
            endcase

            rounded_full = {1'b0, ext_res[EXT_WIDTH-1:3]} + inc;

            if (rounded_full[SIG_WIDTH]) begin
                rounded_full = rounded_full >> 1;
                exp_res = exp_res + 1'b1;
            end

            rounded_sig = rounded_full[SIG_WIDTH-1:0];

            if (rounded_sig == {SIG_WIDTH{1'b0}}) begin
                sum = {(rnd_mode == 3'b011), {EXP_WIDTH{1'b0}}, {MANT_WIDTH{1'b0}}};
                exception_flags = 3'b000;
            end else if (exp_res >= EXP_MAX) begin
                sum = {result_sign, EXP_MAX, {MANT_WIDTH{1'b0}}};
                exception_flags = 3'b010;
            end else if (rounded_sig[SIG_WIDTH-1]) begin
                sum = {result_sign, exp_res[EXP_WIDTH-1:0], rounded_sig[MANT_WIDTH-1:0]};
                exception_flags = (a_denorm || b_denorm) ? 3'b001 : 3'b000;
            end else begin
                sum = {result_sign, {EXP_WIDTH{1'b0}}, rounded_sig[MANT_WIDTH-1:0]};
                exception_flags = (a_denorm || b_denorm || guard_bit || round_bit || sticky_bit) ? 3'b001 : 3'b000;
            end
        end
    end

endmodule