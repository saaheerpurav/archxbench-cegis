`timescale 1ns/1ps

module fp_addsub (
    input sign_large,
    input sign_small,
    input [7:0] exp_in,
    input [26:0] sig_large,
    input [26:0] sig_small,
    output sign_out,
    output [7:0] exp_out,
    output [27:0] mag_out
);

wire same_sign;
wire [27:0] sig_large_ext;
wire [27:0] sig_small_ext;
wire [27:0] add_mag;
wire [27:0] sub_mag;
wire [27:0] result_mag;

assign same_sign = (sign_large == sign_small);

assign sig_large_ext = {1'b0, sig_large};
assign sig_small_ext = {1'b0, sig_small};

assign add_mag = sig_large_ext + sig_small_ext;
assign sub_mag = sig_large_ext - sig_small_ext;

assign result_mag = same_sign ? add_mag : sub_mag;

assign mag_out = result_mag;
assign exp_out = exp_in;

/* The align stage guarantees sig_large >= sig_small for unlike-sign
   subtraction, so the nonzero result keeps sign_large. Exact cancellation
   is reported as +0 for the normalizer/packer path. */
assign sign_out = (result_mag == 28'b0) ? 1'b0 : sign_large;

endmodule