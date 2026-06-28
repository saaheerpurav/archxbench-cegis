`timescale 1ns/1ps

module fp_multiplier_unpack #(
    parameter EXP_WIDTH  = 8,
    parameter MANT_WIDTH = 23,
    parameter WIDTH      = 1 + EXP_WIDTH + MANT_WIDTH
)(
    input  [WIDTH-1:0] operand,

    output reg sign,
    output reg [EXP_WIDTH-1:0] exponent,
    output reg [MANT_WIDTH-1:0] mantissa,

    output reg is_zero,
    output reg is_denormal,
    output reg is_inf,
    output reg is_nan,

    output reg [MANT_WIDTH:0] significand,
    output reg signed [EXP_WIDTH+1:0] unbiased_exp
);

    localparam signed [EXP_WIDTH+1:0] EXP_BIAS =
        (1 << (EXP_WIDTH-1)) - 1;

    localparam signed [EXP_WIDTH+1:0] ONE_EXP =
        {{(EXP_WIDTH+1){1'b0}}, 1'b1};

    always @(*) begin
        sign     = operand[WIDTH-1];
        exponent = operand[WIDTH-2:MANT_WIDTH];
        mantissa = operand[MANT_WIDTH-1:0];

        is_zero     = (exponent == {EXP_WIDTH{1'b0}}) &&
                      (mantissa == {MANT_WIDTH{1'b0}});

        is_denormal = (exponent == {EXP_WIDTH{1'b0}}) &&
                      (mantissa != {MANT_WIDTH{1'b0}});

        is_inf      = (exponent == {EXP_WIDTH{1'b1}}) &&
                      (mantissa == {MANT_WIDTH{1'b0}});

        is_nan      = (exponent == {EXP_WIDTH{1'b1}}) &&
                      (mantissa != {MANT_WIDTH{1'b0}});

        if (is_zero) begin
            significand  = {MANT_WIDTH+1{1'b0}};
            unbiased_exp = {EXP_WIDTH+2{1'b0}};
        end else if (is_denormal) begin
            significand  = {1'b0, mantissa};
            unbiased_exp = ONE_EXP - EXP_BIAS;
        end else begin
            significand  = {1'b1, mantissa};
            unbiased_exp = $signed({2'b00, exponent}) - EXP_BIAS;
        end
    end

endmodule