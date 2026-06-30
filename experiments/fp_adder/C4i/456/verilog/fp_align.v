`timescale 1ns/1ps

module fp_align #(
    parameter integer WIDTH = 32,
    parameter integer EXP_WIDTH = 8,
    parameter integer MANT_WIDTH = WIDTH - EXP_WIDTH - 1
)(
    input a_sign,
    input b_sign,
    input [EXP_WIDTH-1:0] a_exp,
    input [EXP_WIDTH-1:0] b_exp,
    input [MANT_WIDTH-1:0] a_frac,
    input [MANT_WIDTH-1:0] b_frac,
    output reg [EXP_WIDTH:0] aligned_exp,
    output reg large_sign,
    output reg small_sign,
    output reg [MANT_WIDTH+3:0] large_sig,
    output reg [MANT_WIDTH+3:0] small_sig
);

    localparam integer SIG_WIDTH = MANT_WIDTH + 4;

    reg [EXP_WIDTH:0] a_eff_exp;
    reg [EXP_WIDTH:0] b_eff_exp;
    reg [SIG_WIDTH-1:0] a_sig;
    reg [SIG_WIDTH-1:0] b_sig;
    reg [EXP_WIDTH:0] exp_diff;

    function [SIG_WIDTH-1:0] shift_right_sticky;
        input [SIG_WIDTH-1:0] value;
        input [EXP_WIDTH:0] shamt;

        integer i;
        reg sticky;
        reg [SIG_WIDTH-1:0] shifted;

        begin
            if (shamt >= SIG_WIDTH) begin
                shift_right_sticky = {{(SIG_WIDTH-1){1'b0}}, |value};
            end else begin
                shifted = value >> shamt;
                sticky = 1'b0;

                for (i = 0; i < SIG_WIDTH; i = i + 1) begin
                    if (i < shamt)
                        sticky = sticky | value[i];
                end

                shifted[0] = shifted[0] | sticky;
                shift_right_sticky = shifted;
            end
        end
    endfunction

    always @* begin
        a_eff_exp = (a_exp == {EXP_WIDTH{1'b0}}) ? {{EXP_WIDTH{1'b0}}, 1'b1} : {1'b0, a_exp};
        b_eff_exp = (b_exp == {EXP_WIDTH{1'b0}}) ? {{EXP_WIDTH{1'b0}}, 1'b1} : {1'b0, b_exp};

        a_sig = {(a_exp != {EXP_WIDTH{1'b0}}), a_frac, 3'b000};
        b_sig = {(b_exp != {EXP_WIDTH{1'b0}}), b_frac, 3'b000};

        if ((a_eff_exp > b_eff_exp) ||
            ((a_eff_exp == b_eff_exp) && (a_sig >= b_sig))) begin
            aligned_exp = a_eff_exp;
            large_sign = a_sign;
            small_sign = b_sign;
            large_sig = a_sig;

            exp_diff = a_eff_exp - b_eff_exp;
            small_sig = shift_right_sticky(b_sig, exp_diff);
        end else begin
            aligned_exp = b_eff_exp;
            large_sign = b_sign;
            small_sign = a_sign;
            large_sig = b_sig;

            exp_diff = b_eff_exp - a_eff_exp;
            small_sig = shift_right_sticky(a_sig, exp_diff);
        end
    end

endmodule