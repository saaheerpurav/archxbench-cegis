`timescale 1ns/1ps

module fp_special_cases #(
    parameter integer WIDTH = 32,
    parameter integer EXP_WIDTH = 8,
    parameter integer MANT_WIDTH = WIDTH - EXP_WIDTH - 1
)(
    input  [WIDTH-1:0] a,
    input  [WIDTH-1:0] b,
    input  [2:0] rnd_mode,
    input  a_sign,
    input  b_sign,
    input  a_zero,
    input  b_zero,
    input  a_inf,
    input  b_inf,
    input  a_nan,
    input  b_nan,
    output reg special_valid,
    output reg [WIDTH-1:0] special_sum,
    output reg [2:0] special_flags
);

    localparam [EXP_WIDTH-1:0]  EXP_ALL_ONES = {EXP_WIDTH{1'b1}};
    localparam [EXP_WIDTH-1:0]  EXP_ZERO     = {EXP_WIDTH{1'b0}};
    localparam [MANT_WIDTH-1:0] FRAC_ZERO    = {MANT_WIDTH{1'b0}};
    localparam [MANT_WIDTH-1:0] QNAN_FRAC    = {1'b1, {(MANT_WIDTH-1){1'b0}}};

    localparam [2:0] FLAG_NONE    = 3'b000;
    localparam [2:0] FLAG_INVALID = 3'b100;

    localparam [2:0] RND_TOWARD_NEG = 3'b011;

    always @* begin
        special_valid = 1'b0;
        special_sum   = {WIDTH{1'b0}};
        special_flags = FLAG_NONE;

        if (a_nan || b_nan) begin
            special_valid = 1'b1;
            special_sum   = {1'b0, EXP_ALL_ONES, QNAN_FRAC};
            special_flags = FLAG_INVALID;
        end else if (a_inf && b_inf && (a_sign != b_sign)) begin
            special_valid = 1'b1;
            special_sum   = {1'b0, EXP_ALL_ONES, QNAN_FRAC};
            special_flags = FLAG_INVALID;
        end else if (a_inf) begin
            special_valid = 1'b1;
            special_sum   = {a_sign, EXP_ALL_ONES, FRAC_ZERO};
            special_flags = FLAG_NONE;
        end else if (b_inf) begin
            special_valid = 1'b1;
            special_sum   = {b_sign, EXP_ALL_ONES, FRAC_ZERO};
            special_flags = FLAG_NONE;
        end else if (a_zero && b_zero) begin
            special_valid = 1'b1;
            special_sum   = {(rnd_mode == RND_TOWARD_NEG), EXP_ZERO, FRAC_ZERO};
            special_flags = FLAG_NONE;
        end else if (a_zero) begin
            special_valid = 1'b1;
            special_sum   = b;
            special_flags = FLAG_NONE;
        end else if (b_zero) begin
            special_valid = 1'b1;
            special_sum   = a;
            special_flags = FLAG_NONE;
        end
    end

endmodule