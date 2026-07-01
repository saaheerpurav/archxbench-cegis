`timescale 1ns/1ps

module fp_mult_round (
    input [23:0] mantissa_in,
    input guard_bit,
    input round_bit,
    input sticky_bit,
    input signed [10:0] exp_in,
    output [23:0] mantissa_out,
    output signed [10:0] exp_out
);
    wire lsb_bit;
    wire round_increment;
    wire [24:0] rounded_mantissa;

    assign lsb_bit = mantissa_in[0];

    // Round to nearest even:
    // increment when more than half, or exactly half with odd LSB.
    assign round_increment = guard_bit & (round_bit | sticky_bit | lsb_bit);

    assign rounded_mantissa = {1'b0, mantissa_in} + {24'b0, round_increment};

    assign mantissa_out = rounded_mantissa[24] ? 24'h800000 : rounded_mantissa[23:0];
    assign exp_out = rounded_mantissa[24] ? (exp_in + 11'sd1) : exp_in;
endmodule