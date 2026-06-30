`timescale 1ns/1ps

module fp_special_cases #(
    parameter EXP_WIDTH  = 8,
    parameter MANT_WIDTH = 23,
    parameter WIDTH      = 1 + EXP_WIDTH + MANT_WIDTH
)(
    input  sign_a,
    input  sign_b,
    input  is_zero_a,
    input  is_zero_b,
    input  is_inf_a,
    input  is_inf_b,
    input  is_nan_a,
    input  is_nan_b,
    output reg special_valid,
    output reg [WIDTH-1:0] special_result,
    output reg [2:0] exception_flags
);

    localparam [EXP_WIDTH-1:0]  EXP_MAX   = {EXP_WIDTH{1'b1}};
    localparam [EXP_WIDTH-1:0]  EXP_ZERO  = {EXP_WIDTH{1'b0}};
    localparam [MANT_WIDTH-1:0] MANT_ZERO = {MANT_WIDTH{1'b0}};
    localparam [MANT_WIDTH-1:0] QNAN_MANT = {1'b1, {(MANT_WIDTH-1){1'b0}}};

    wire result_sign;
    assign result_sign = sign_a ^ sign_b;

    always @(*) begin
        special_valid   = 1'b0;
        special_result  = {WIDTH{1'b0}};
        exception_flags = 3'b000;

        if (is_nan_a || is_nan_b) begin
            special_valid   = 1'b1;
            special_result  = {1'b0, EXP_MAX, QNAN_MANT};
            exception_flags = 3'b100;
        end else if ((is_inf_a && is_zero_b) || (is_inf_b && is_zero_a)) begin
            special_valid   = 1'b1;
            special_result  = {1'b0, EXP_MAX, QNAN_MANT};
            exception_flags = 3'b100;
        end else if (is_inf_a || is_inf_b) begin
            special_valid   = 1'b1;
            special_result  = {result_sign, EXP_MAX, MANT_ZERO};
            exception_flags = 3'b010;
        end else if (is_zero_a || is_zero_b) begin
            special_valid   = 1'b1;
            special_result  = {result_sign, EXP_ZERO, MANT_ZERO};
            exception_flags = 3'b001;
        end
    end

endmodule