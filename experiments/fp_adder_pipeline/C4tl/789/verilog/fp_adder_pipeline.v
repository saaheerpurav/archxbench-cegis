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

wire        a_sign_w, b_sign_w;
wire [7:0]  a_exp_w, b_exp_w;
wire [23:0] a_mant_w, b_mant_w;
wire        a_zero_w, b_zero_w, a_inf_w, b_inf_w, a_nan_w, b_nan_w;

fp_unpack u_unpack_a (
    .in(a),
    .sign(a_sign_w),
    .exp(a_exp_w),
    .mant(a_mant_w),
    .is_zero(a_zero_w),
    .is_inf(a_inf_w),
    .is_nan(a_nan_w)
);

fp_unpack u_unpack_b (
    .in(b),
    .sign(b_sign_w),
    .exp(b_exp_w),
    .mant(b_mant_w),
    .is_zero(b_zero_w),
    .is_inf(b_inf_w),
    .is_nan(b_nan_w)
);

wire        special_valid_w;
wire [31:0] special_result_w;
wire        b_eff_sign_w = b_sign_w ^ add_sub;

fp_special_cases u_special_in (
    .a_sign(a_sign_w),
    .b_sign(b_eff_sign_w),
    .a_exp(a_exp_w),
    .b_exp(b_exp_w),
    .a_frac(a[22:0]),
    .b_frac(b[22:0]),
    .a_zero(a_zero_w),
    .b_zero(b_zero_w),
    .a_inf(a_inf_w),
    .b_inf(b_inf_w),
    .a_nan(a_nan_w),
    .b_nan(b_nan_w),
    .special_valid(special_valid_w),
    .special_result(special_result_w)
);

reg        s1_a_sign, s1_b_sign;
reg [7:0]  s1_a_exp, s1_b_exp;
reg [23:0] s1_a_mant, s1_b_mant;
reg        s1_special_valid;
reg [31:0] s1_special_result;

always @(posedge clk) begin
    if (rst) begin
        s1_a_sign <= 1'b0;
        s1_b_sign <= 1'b0;
        s1_a_exp <= 8'd0;
        s1_b_exp <= 8'd0;
        s1_a_mant <= 24'd0;
        s1_b_mant <= 24'd0;
        s1_special_valid <= 1'b0;
        s1_special_result <= 32'd0;
    end else begin
        s1_a_sign <= a_sign_w;
        s1_b_sign <= b_eff_sign_w;
        s1_a_exp <= a_exp_w;
        s1_b_exp <= b_exp_w;
        s1_a_mant <= a_mant_w;
        s1_b_mant <= b_mant_w;
        s1_special_valid <= special_valid_w;
        s1_special_result <= special_result_w;
    end
end

wire [27:0] align_a_w, align_b_w;
wire [7:0]  align_exp_w;

fp_align u_align (
    .a_exp(s1_a_exp),
    .b_exp(s1_b_exp),
    .a_mant(s1_a_mant),
    .b_mant(s1_b_mant),
    .a_aligned(align_a_w),
    .b_aligned(align_b_w),
    .common_exp(align_exp_w)
);

reg        s2_a_sign, s2_b_sign;
reg [27:0] s2_a_aligned, s2_b_aligned;
reg [7:0]  s2_exp;
reg        s2_special_valid;
reg [31:0] s2_special_result;

always @(posedge clk) begin
    if (rst) begin
        s2_a_sign <= 1'b0;
        s2_b_sign <= 1'b0;
        s2_a_aligned <= 28'd0;
        s2_b_aligned <= 28'd0;
        s2_exp <= 8'd0;
        s2_special_valid <= 1'b0;
        s2_special_result <= 32'd0;
    end else begin
        s2_a_sign <= s1_a_sign;
        s2_b_sign <= s1_b_sign;
        s2_a_aligned <= align_a_w;
        s2_b_aligned <= align_b_w;
        s2_exp <= align_exp_w;
        s2_special_valid <= s1_special_valid;
        s2_special_result <= s1_special_result;
    end
end

wire        add_sign_w;
wire [27:0] add_mant_w;
wire        add_zero_w;

fp_addsub u_addsub (
    .a_sign(s2_a_sign),
    .b_sign(s2_b_sign),
    .a_mant(s2_a_aligned),
    .b_mant(s2_b_aligned),
    .result_sign(add_sign_w),
    .result_mant(add_mant_w),
    .is_zero(add_zero_w)
);

reg        s3_sign;
reg [27:0] s3_mant;
reg [7:0]  s3_exp;
reg        s3_zero;
reg        s3_special_valid;
reg [31:0] s3_special_result;

always @(posedge clk) begin
    if (rst) begin
        s3_sign <= 1'b0;
        s3_mant <= 28'd0;
        s3_exp <= 8'd0;
        s3_zero <= 1'b1;
        s3_special_valid <= 1'b0;
        s3_special_result <= 32'd0;
    end else begin
        s3_sign <= add_sign_w;
        s3_mant <= add_mant_w;
        s3_exp <= s2_exp;
        s3_zero <= add_zero_w;
        s3_special_valid <= s2_special_valid;
        s3_special_result <= s2_special_result;
    end
end

wire [31:0] normal_result_w;

fp_normalize_round u_normalize_round (
    .sign_in(s3_sign),
    .exp_in(s3_exp),
    .mant_in(s3_mant),
    .is_zero(s3_zero),
    .result(normal_result_w)
);

reg [31:0] s4_result;
reg        s4_special_valid;
reg [31:0] s4_special_result;

always @(posedge clk) begin
    if (rst) begin
        s4_result <= 32'd0;
        s4_special_valid <= 1'b0;
        s4_special_result <= 32'd0;
    end else begin
        s4_result <= normal_result_w;
        s4_special_valid <= s3_special_valid;
        s4_special_result <= s3_special_result;
    end
end

reg [31:0] result_r;
reg [LATENCY-1:0] valid_pipe;

always @(posedge clk) begin
    if (rst) begin
        result_r <= 32'd0;
        valid_pipe <= {LATENCY{1'b0}};
    end else begin
        result_r <= s4_special_valid ? s4_special_result : s4_result;
        valid_pipe <= {valid_pipe[LATENCY-2:0], valid_in};
    end
end

assign result = result_r;
assign valid_out = valid_pipe[LATENCY-1];

endmodule