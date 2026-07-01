`timescale 1ns/1ps

module fp_round_pack (
    input sign_in,
    input [7:0] exp_in,
    input [26:0] sig_in,
    input is_zero,
    output [31:0] result
);

reg [31:0] result_r;

wire [23:0] sig_main = sig_in[26:3];
wire guard_bit = sig_in[2];
wire round_bit = sig_in[1];
wire sticky_bit = sig_in[0];

wire lsb_bit = sig_main[0];
wire round_inc = guard_bit & (round_bit | sticky_bit | lsb_bit);

wire [24:0] rounded_sig = {1'b0, sig_main} + {24'b0, round_inc};
wire round_carry = rounded_sig[24];

wire [7:0] exp_rounded = exp_in + {7'b0, round_carry};
wire [23:0] sig_rounded = round_carry ? rounded_sig[24:1] : rounded_sig[23:0];

always @(*) begin
    if (is_zero) begin
        result_r = {sign_in, 8'b0, 23'b0};
    end else if (exp_in == 8'hff) begin
        if (sig_in[25:3] != 23'b0)
            result_r = {sign_in, 8'hff, sig_in[25:3] | 23'h400000};
        else
            result_r = {sign_in, 8'hff, 23'b0};
    end else if (exp_rounded >= 8'hff) begin
        result_r = {sign_in, 8'hff, 23'b0};
    end else if (exp_rounded == 8'b0) begin
        result_r = {sign_in, 8'b0, sig_rounded[22:0]};
    end else begin
        result_r = {sign_in, exp_rounded, sig_rounded[22:0]};
    end
end

assign result = result_r;

endmodule