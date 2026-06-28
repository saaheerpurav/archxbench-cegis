`timescale 1ns/1ps

module fp_pack_result (
    input sign,
    input is_nan,
    input is_inf,
    input is_zero,
    input [23:0] significand_rounded,
    input signed [12:0] exponent_rounded,
    output reg [31:0] result
);

    localparam [31:0] CANONICAL_NAN = 32'h7FC00000;

    localparam signed [12:0] EXP_BIAS      = 13'sd127;
    localparam signed [12:0] EXP_MAX_NORM  = 13'sd127;
    localparam signed [12:0] EXP_MIN_NORM  = -13'sd126;

    reg [7:0] exponent_field;

    always @* begin
        exponent_field = 8'd0;
        result = 32'd0;

        if (is_nan) begin
            result = CANONICAL_NAN;
        end else if (is_inf) begin
            result = {sign, 8'hFF, 23'd0};
        end else if (is_zero) begin
            result = {sign, 31'd0};
        end else if (exponent_rounded > EXP_MAX_NORM) begin
            result = {sign, 8'hFF, 23'd0};
        end else if (exponent_rounded < EXP_MIN_NORM) begin
            result = {sign, 31'd0};
        end else begin
            exponent_field = exponent_rounded + EXP_BIAS;
            result = {sign, exponent_field, significand_rounded[22:0]};
        end
    end

endmodule