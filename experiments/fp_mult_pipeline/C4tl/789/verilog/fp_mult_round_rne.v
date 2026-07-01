`timescale 1ns/1ps

module fp_mult_round_rne (
    input signed [10:0] exp_in,
    input [23:0] mantissa_in,
    input guard_bit,
    input round_bit,
    input sticky_bit,
    output signed [10:0] exp_out,
    output [23:0] mantissa_out
);

wire increment;
wire [24:0] rounded_mantissa;

assign increment = guard_bit && (round_bit || sticky_bit || mantissa_in[0]);
assign rounded_mantissa = {1'b0, mantissa_in} + {24'b0, increment};

assign mantissa_out = rounded_mantissa[24] ? 24'h800000 : rounded_mantissa[23:0];
assign exp_out = rounded_mantissa[24] ? (exp_in + 11'sd1) : exp_in;

endmodule