`timescale 1ns/1ps

module fp_significand_multiply #(
    parameter EXP_WIDTH  = 8,
    parameter MANT_WIDTH = 23
)(
    input  wire                         sign_a,
    input  wire                         sign_b,
    input  wire [EXP_WIDTH-1:0]          exp_a,
    input  wire [EXP_WIDTH-1:0]          exp_b,
    input  wire [MANT_WIDTH-1:0]         mant_a,
    input  wire [MANT_WIDTH-1:0]         mant_b,
    output wire                         result_sign,
    output wire signed [EXP_WIDTH+2:0]   raw_exp,
    output wire [(2*(MANT_WIDTH+1))-1:0] sig_product
);

    localparam integer RAW_EXP_WIDTH = EXP_WIDTH + 3;
    localparam integer BIAS          = (1 << (EXP_WIDTH - 1)) - 1;

    wire [MANT_WIDTH:0] sig_a;
    wire [MANT_WIDTH:0] sig_b;

    wire signed [RAW_EXP_WIDTH-1:0] exp_a_ext;
    wire signed [RAW_EXP_WIDTH-1:0] exp_b_ext;
    wire signed [RAW_EXP_WIDTH-1:0] bias_ext;

    assign result_sign = sign_a ^ sign_b;

    assign sig_a = {1'b1, mant_a};
    assign sig_b = {1'b1, mant_b};

    assign sig_product = sig_a * sig_b;

    assign exp_a_ext = $signed({{(RAW_EXP_WIDTH-EXP_WIDTH){1'b0}}, exp_a});
    assign exp_b_ext = $signed({{(RAW_EXP_WIDTH-EXP_WIDTH){1'b0}}, exp_b});
    assign bias_ext  = $signed(BIAS[RAW_EXP_WIDTH-1:0]);

    assign raw_exp = exp_a_ext + exp_b_ext - bias_ext;

endmodule