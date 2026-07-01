`timescale 1ns/1ps

module fp_adder_pipeline #(
    parameter LATENCY = 5
) (
    input clk,
    input rst,
    input [31:0] a,
    input [31:0] b,
    input add_sub,
    input valid_in,
    output [31:0] result,
    output valid_out
);

wire        a_sign;
wire [7:0]  a_exp;
wire [22:0] a_frac;
wire [23:0] a_sig;
wire        a_zero;
wire        a_inf;
wire        a_nan;
wire        a_denorm;

wire        b_sign_raw;
wire [7:0]  b_exp;
wire [22:0] b_frac;
wire [23:0] b_sig;
wire        b_zero;
wire        b_inf;
wire        b_nan;
wire        b_denorm;

wire        b_eff_sign;

wire        special_valid;
wire [31:0] special_result;

wire        align_sign_large;
wire        align_sign_small;
wire [7:0]  align_exp;
wire [26:0] align_sig_large;
wire [26:0] align_sig_small;

wire        add_sign;
wire [7:0]  add_exp;
wire [27:0] add_sig;
wire        add_zero;

wire [31:0] normal_result;
wire [31:0] comb_result;

reg [31:0] result_pipe [0:LATENCY-1];
reg        valid_pipe  [0:LATENCY-1];

integer i;

assign b_eff_sign = b_sign_raw ^ add_sub;
assign comb_result = special_valid ? special_result : normal_result;

fp_unpack u_unpack_a (
    .operand(a),
    .sign(a_sign),
    .exp(a_exp),
    .frac(a_frac),
    .sig(a_sig),
    .is_zero(a_zero),
    .is_inf(a_inf),
    .is_nan(a_nan),
    .is_denorm(a_denorm)
);

fp_unpack u_unpack_b (
    .operand(b),
    .sign(b_sign_raw),
    .exp(b_exp),
    .frac(b_frac),
    .sig(b_sig),
    .is_zero(b_zero),
    .is_inf(b_inf),
    .is_nan(b_nan),
    .is_denorm(b_denorm)
);

fp_special_cases u_special (
    .a_sign(a_sign),
    .a_exp(a_exp),
    .a_frac(a_frac),
    .a_zero(a_zero),
    .a_inf(a_inf),
    .a_nan(a_nan),
    .b_sign(b_eff_sign),
    .b_exp(b_exp),
    .b_frac(b_frac),
    .b_zero(b_zero),
    .b_inf(b_inf),
    .b_nan(b_nan),
    .special_valid(special_valid),
    .special_result(special_result)
);

fp_align u_align (
    .a_sign(a_sign),
    .a_exp(a_exp),
    .a_sig(a_sig),
    .b_sign(b_eff_sign),
    .b_exp(b_exp),
    .b_sig(b_sig),
    .sign_large(align_sign_large),
    .sign_small(align_sign_small),
    .exp_large(align_exp),
    .sig_large(align_sig_large),
    .sig_small(align_sig_small)
);

fp_addsub_significands u_addsub (
    .sign_large(align_sign_large),
    .sign_small(align_sign_small),
    .exp_in(align_exp),
    .sig_large(align_sig_large),
    .sig_small(align_sig_small),
    .result_sign(add_sign),
    .result_exp(add_exp),
    .result_sig(add_sig),
    .result_zero(add_zero)
);

fp_normalize_round_pack u_pack (
    .sign_in(add_sign),
    .exp_in(add_exp),
    .sig_in(add_sig),
    .is_zero(add_zero),
    .result(normal_result)
);

generate
    if (LATENCY <= 0) begin : gen_no_latency
        assign result = comb_result;
        assign valid_out = valid_in;
    end else begin : gen_pipe
        assign result = result_pipe[LATENCY-1];
        assign valid_out = valid_pipe[LATENCY-1];

        always @(posedge clk) begin
            if (rst) begin
                for (i = 0; i < LATENCY; i = i + 1) begin
                    result_pipe[i] <= 32'h00000000;
                    valid_pipe[i] <= 1'b0;
                end
            end else begin
                result_pipe[0] <= comb_result;
                valid_pipe[0] <= valid_in;
                for (i = 1; i < LATENCY; i = i + 1) begin
                    result_pipe[i] <= result_pipe[i-1];
                    valid_pipe[i] <= valid_pipe[i-1];
                end
            end
        end
    end
endgenerate

endmodule