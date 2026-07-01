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

wire sign_a;
wire sign_b_raw;
wire [7:0] exp_a;
wire [7:0] exp_b;
wire [22:0] frac_a;
wire [22:0] frac_b;
wire [23:0] sig_a;
wire [23:0] sig_b;
wire zero_a;
wire zero_b;
wire inf_a;
wire inf_b;
wire nan_a;
wire nan_b;

wire sign_b_eff;
wire special_valid;
wire [31:0] special_result;

wire op_sub_eff;
wire res_sign_align;
wire [7:0] exp_common;
wire [27:0] sig_large;
wire [27:0] sig_small;

wire res_sign_add;
wire [7:0] exp_add;
wire [27:0] sig_sum;
wire exact_zero;

wire [31:0] normal_result;
wire [31:0] comb_result;

reg [31:0] result_pipe [0:LATENCY-1];
reg [LATENCY-1:0] valid_pipe;

integer i;

fp_adder_unpack u_unpack_a (
    .in(a),
    .sign(sign_a),
    .exp(exp_a),
    .frac(frac_a),
    .sig(sig_a),
    .is_zero(zero_a),
    .is_inf(inf_a),
    .is_nan(nan_a)
);

fp_adder_unpack u_unpack_b (
    .in(b),
    .sign(sign_b_raw),
    .exp(exp_b),
    .frac(frac_b),
    .sig(sig_b),
    .is_zero(zero_b),
    .is_inf(inf_b),
    .is_nan(nan_b)
);

fp_adder_special u_special (
    .a(a),
    .b(b),
    .add_sub(add_sub),
    .sign_a(sign_a),
    .sign_b_raw(sign_b_raw),
    .zero_a(zero_a),
    .zero_b(zero_b),
    .inf_a(inf_a),
    .inf_b(inf_b),
    .nan_a(nan_a),
    .nan_b(nan_b),
    .sign_b_eff(sign_b_eff),
    .special_valid(special_valid),
    .special_result(special_result)
);

fp_adder_align u_align (
    .sign_a(sign_a),
    .sign_b(sign_b_eff),
    .exp_a(exp_a),
    .exp_b(exp_b),
    .sig_a(sig_a),
    .sig_b(sig_b),
    .op_sub(op_sub_eff),
    .res_sign(res_sign_align),
    .exp_common(exp_common),
    .sig_large(sig_large),
    .sig_small(sig_small)
);

fp_adder_addsub u_addsub (
    .op_sub(op_sub_eff),
    .res_sign_in(res_sign_align),
    .exp_in(exp_common),
    .sig_large(sig_large),
    .sig_small(sig_small),
    .res_sign(res_sign_add),
    .exp_out(exp_add),
    .sig_out(sig_sum),
    .exact_zero(exact_zero)
);

fp_adder_normalize_round u_norm_round (
    .sign_in(res_sign_add),
    .exp_in(exp_add),
    .sig_in(sig_sum),
    .exact_zero(exact_zero),
    .result(normal_result)
);

assign comb_result = special_valid ? special_result : normal_result;

generate
if (LATENCY <= 0) begin : gen_no_pipe
    assign result = comb_result;
    assign valid_out = valid_in;
end else begin : gen_pipe
    assign result = result_pipe[LATENCY-1];
    assign valid_out = valid_pipe[LATENCY-1];

    always @(posedge clk) begin
        if (rst) begin
            valid_pipe <= {LATENCY{1'b0}};
            for (i = 0; i < LATENCY; i = i + 1)
                result_pipe[i] <= 32'b0;
        end else begin
            valid_pipe[0] <= valid_in;
            result_pipe[0] <= comb_result;

            for (i = 1; i < LATENCY; i = i + 1) begin
                valid_pipe[i] <= valid_pipe[i-1];
                result_pipe[i] <= result_pipe[i-1];
            end
        end
    end
end
endgenerate

endmodule