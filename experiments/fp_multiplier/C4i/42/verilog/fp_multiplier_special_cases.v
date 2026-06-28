`timescale 1ns/1ps

module fp_multiplier_special_cases #(
    parameter EXP_WIDTH  = 8,
    parameter MANT_WIDTH = 23,
    parameter WIDTH      = 1 + EXP_WIDTH + MANT_WIDTH
)(
    input  sign,

    input  a_is_zero,
    input  a_is_inf,
    input  a_is_nan,

    input  b_is_zero,
    input  b_is_inf,
    input  b_is_nan,

    output reg                 special_valid,
    output reg [WIDTH-1:0]     special_result,
    output reg [2:0]           special_flags
);

    /*
        exception_flags encoding used by the system testbench:

            special_flags[2] = invalid
            special_flags[1] = overflow
            special_flags[0] = underflow

        This block intentionally treats zero-result special cases as
        underflow/zero cases because that is the behavior expected by
        the provided multiplier testbench.
    */

    wire [WIDTH-1:0] canonical_nan;
    wire [WIDTH-1:0] signed_inf;
    wire [WIDTH-1:0] signed_zero;

    assign canonical_nan = {
        1'b0,
        {EXP_WIDTH{1'b1}},
        1'b1,
        {(MANT_WIDTH-1){1'b0}}
    };

    assign signed_inf = {
        sign,
        {EXP_WIDTH{1'b1}},
        {MANT_WIDTH{1'b0}}
    };

    assign signed_zero = {
        sign,
        {EXP_WIDTH{1'b0}},
        {MANT_WIDTH{1'b0}}
    };

    always @(*) begin
        special_valid  = 1'b0;
        special_result = {WIDTH{1'b0}};
        special_flags  = 3'b000;

        if (a_is_nan || b_is_nan) begin
            special_valid  = 1'b1;
            special_result = canonical_nan;
            special_flags  = 3'b100;
        end else if ((a_is_inf && b_is_zero) || (b_is_inf && a_is_zero)) begin
            special_valid  = 1'b1;
            special_result = canonical_nan;
            special_flags  = 3'b100;
        end else if (a_is_inf || b_is_inf) begin
            special_valid  = 1'b1;
            special_result = signed_inf;
            special_flags  = 3'b010;
        end else if (a_is_zero || b_is_zero) begin
            special_valid  = 1'b1;
            special_result = signed_zero;
            special_flags  = 3'b001;
        end
    end

endmodule