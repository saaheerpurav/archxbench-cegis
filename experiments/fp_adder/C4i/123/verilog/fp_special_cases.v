`timescale 1ns/1ps

module fp_special_cases #(
    parameter WIDTH = 32,
    parameter EXP_WIDTH = 8,
    parameter MANT_WIDTH = 23
)(
    input  [WIDTH-1:0] a,
    input  [WIDTH-1:0] b,
    input  [2:0]       rnd_mode,
    input              sign_a,
    input              sign_b,
    input              a_zero,
    input              b_zero,
    input              a_inf,
    input              b_inf,
    input              a_nan,
    input              b_nan,
    output reg         special_valid,
    output reg [WIDTH-1:0] special_sum,
    output reg [2:0]   special_flags
);

    localparam [EXP_WIDTH-1:0] EXP_MAX = {EXP_WIDTH{1'b1}};

    wire [WIDTH-1:0] canonical_qnan;
    wire zero_sign;

    assign canonical_qnan = {
        1'b0,
        EXP_MAX,
        1'b1,
        {(MANT_WIDTH-1){1'b0}}
    };

    assign zero_sign = (rnd_mode == 3'b011) ? (sign_a | sign_b) : (sign_a & sign_b);

    always @(*) begin
        special_valid = 1'b0;
        special_sum   = {WIDTH{1'b0}};
        special_flags = 3'b000;

        if (a_nan || b_nan) begin
            special_valid = 1'b1;
            special_sum   = canonical_qnan;
            special_flags = 3'b100;
        end else if (a_inf && b_inf && (sign_a != sign_b)) begin
            special_valid = 1'b1;
            special_sum   = canonical_qnan;
            special_flags = 3'b100;
        end else if (a_inf) begin
            special_valid = 1'b1;
            special_sum   = a;
            special_flags = 3'b000;
        end else if (b_inf) begin
            special_valid = 1'b1;
            special_sum   = b;
            special_flags = 3'b000;
        end else if (a_zero && b_zero) begin
            special_valid = 1'b1;
            special_sum   = {zero_sign, {EXP_WIDTH{1'b0}}, {MANT_WIDTH{1'b0}}};
            special_flags = 3'b000;
        end else if (a_zero) begin
            special_valid = 1'b1;
            special_sum   = b;
            special_flags = 3'b000;
        end else if (b_zero) begin
            special_valid = 1'b1;
            special_sum   = a;
            special_flags = 3'b000;
        end
    end

endmodule