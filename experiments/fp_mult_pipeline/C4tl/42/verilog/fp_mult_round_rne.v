`timescale 1ns/1ps

module fp_mult_round_rne (
    input [23:0] sig_in,
    input guard_bit,
    input round_bit,
    input sticky_bit,
    input signed [9:0] exp_in,
    output [23:0] sig_rounded,
    output signed [9:0] exp_rounded
);

wire lsb_bit;
wire round_increment;
wire [24:0] sig_incremented;
wire sig_carry;

assign lsb_bit = sig_in[0];

// Round-to-nearest-even:
// increment when the discarded bits are greater than half,
// or exactly half with an odd retained significand.
assign round_increment = guard_bit & (round_bit | sticky_bit | lsb_bit);

assign sig_incremented = {1'b0, sig_in} + {24'b0, round_increment};
assign sig_carry = sig_incremented[24];

// If rounding overflows 1.111... to 10.000..., renormalize to 1.000...
// and increment the exponent.
assign sig_rounded = sig_carry ? 24'h800000 : sig_incremented[23:0];
assign exp_rounded = sig_carry ? (exp_in + 10'sd1) : exp_in;

endmodule