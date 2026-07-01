`timescale 1ns/1ps

module fp_adder_addsub (
    input op_sub,
    input res_sign_in,
    input [7:0] exp_in,
    input [27:0] sig_large,
    input [27:0] sig_small,
    output res_sign,
    output [7:0] exp_out,
    output [27:0] sig_out,
    output exact_zero
);

wire [28:0] add_result;
wire [27:0] sub_result;
wire add_carry;
wire [27:0] add_shifted;

assign add_result = {1'b0, sig_large} + {1'b0, sig_small};
assign sub_result = sig_large - sig_small;

assign add_carry = add_result[28];

/*
 * On an addition carry-out, shift right by one bit immediately and fold
 * the discarded bit into the sticky position. This keeps the 28-bit
 * significand format intact for the normalize/round stage.
 */
assign add_shifted = {add_result[28:2], add_result[1] | add_result[0]};

assign exact_zero = op_sub ? (sig_large == sig_small) : (add_result == 29'b0);

assign res_sign = exact_zero ? 1'b0 : res_sign_in;

assign exp_out = exact_zero ? 8'b0 :
                 (!op_sub && add_carry) ? ((exp_in == 8'hff) ? 8'hff : exp_in + 8'd1) :
                 exp_in;

assign sig_out = exact_zero ? 28'b0 :
                 op_sub ? sub_result :
                 add_carry ? add_shifted :
                 add_result[27:0];

endmodule