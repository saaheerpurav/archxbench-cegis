`timescale 1ns/1ps

module fp_special_cases #(
    parameter EXP_WIDTH  = 8,
    parameter MANT_WIDTH = 23,
    parameter WIDTH      = 1 + EXP_WIDTH + MANT_WIDTH
)(
    input  wire sign_a,
    input  wire sign_b,
    input  wire a_is_zero,
    input  wire a_is_inf,
    input  wire a_is_nan,
    input  wire b_is_zero,
    input  wire b_is_inf,
    input  wire b_is_nan,
    output reg  special_valid,
    output reg  [WIDTH-1:0] special_result,
    output reg  [2:0] special_flags
);

    localparam [EXP_WIDTH-1:0]  EXP_ALL_ONES = {EXP_WIDTH{1'b1}};
    localparam [EXP_WIDTH-1:0]  EXP_ZERO     = {EXP_WIDTH{1'b0}};
    localparam [MANT_WIDTH-1:0] MANT_ZERO    = {MANT_WIDTH{1'b0}};
    localparam [MANT_WIDTH-1:0] QUIET_NAN_MANT =
        {1'b1, {(MANT_WIDTH-1){1'b0}}};

    wire result_sign = sign_a ^ sign_b;

    always @(*) begin
        special_valid  = 1'b0;
        special_result = {WIDTH{1'b0}};
        special_flags  = 3'b000;

        if (a_is_nan || b_is_nan) begin
            special_valid  = 1'b1;
            special_result = {1'b0, EXP_ALL_ONES, QUIET_NAN_MANT};
            special_flags  = 3'b100;
        end else if ((a_is_inf && b_is_zero) || (b_is_inf && a_is_zero)) begin
            special_valid  = 1'b1;
            special_result = {1'b0, EXP_ALL_ONES, QUIET_NAN_MANT};
            special_flags  = 3'b100;
        end else if (a_is_inf || b_is_inf) begin
            special_valid  = 1'b1;
            special_result = {result_sign, EXP_ALL_ONES, MANT_ZERO};
            special_flags  = 3'b010;
        end else if (a_is_zero || b_is_zero) begin
            special_valid  = 1'b1;
            special_result = {result_sign, EXP_ZERO, MANT_ZERO};
            special_flags  = 3'b001;
        end
    end

endmodule