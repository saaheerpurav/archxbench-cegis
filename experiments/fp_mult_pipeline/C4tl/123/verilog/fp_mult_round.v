`timescale 1ns/1ps

module fp_mult_round (
    input signed [10:0] norm_exp_unbiased,
    input [23:0] norm_sig,
    input guard_bit,
    input round_bit,
    input sticky_bit,
    output signed [10:0] rounded_exp_unbiased,
    output [23:0] rounded_sig
);

wire round_increment;
wire [24:0] rounded_sig_ext;
wire carry_out;

assign round_increment = guard_bit && (round_bit || sticky_bit || norm_sig[0]);
assign rounded_sig_ext = {1'b0, norm_sig} + {24'd0, round_increment};
assign carry_out = rounded_sig_ext[24];

assign rounded_sig = carry_out ? rounded_sig_ext[24:1] : rounded_sig_ext[23:0];
assign rounded_exp_unbiased = norm_exp_unbiased + {{10{1'b0}}, carry_out};

endmodule