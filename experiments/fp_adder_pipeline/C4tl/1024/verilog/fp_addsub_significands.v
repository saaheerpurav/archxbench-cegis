`timescale 1ns/1ps

module fp_addsub_significands (
    input        sign_large,
    input        sign_small,
    input [7:0]  exp_in,
    input [26:0] sig_large,
    input [26:0] sig_small,
    output       result_sign,
    output [7:0] result_exp,
    output [27:0] result_sig,
    output       result_zero
);

wire same_sign;
wire [27:0] add_sig;
wire [27:0] sub_sig;
wire exact_cancel;

assign same_sign    = (sign_large == sign_small);
assign add_sig      = {1'b0, sig_large} + {1'b0, sig_small};
assign sub_sig      = {1'b0, sig_large} - {1'b0, sig_small};
assign exact_cancel = (!same_sign) && (sig_large == sig_small);

assign result_sig  = same_sign ? add_sig : sub_sig;
assign result_zero = exact_cancel;
assign result_sign = exact_cancel ? 1'b0 : sign_large;
assign result_exp  = exact_cancel ? 8'b0 : exp_in;

endmodule