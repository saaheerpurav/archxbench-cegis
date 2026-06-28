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

localparam EXTRA_DELAY = (LATENCY > 4) ? (LATENCY - 4) : 0;

/* -------------------------------------------------------------------------
 * Stage 1 combinational: unpack + special-case detection
 * ---------------------------------------------------------------------- */
wire        a_sign_w;
wire [7:0]  a_exp_w;
wire [22:0] a_frac_w;
wire [7:0]  a_exp_eff_w;
wire [23:0] a_sig_w;
wire        a_zero_w;
wire        a_inf_w;
wire        a_nan_w;

wire        b_sign_raw_w;
wire [7:0]  b_exp_w;
wire [22:0] b_frac_w;
wire [7:0]  b_exp_eff_w;
wire [23:0] b_sig_w;
wire        b_zero_w;
wire        b_inf_w;
wire        b_nan_w;

wire        b_sign_eff_w;

wire        special_valid_w;
wire [31:0] special_result_w;

fp_unpack u_unpack_a (
    .operand(a),
    .sign(a_sign_w),
    .exp(a_exp_w),
    .frac(a_frac_w),
    .exp_eff(a_exp_eff_w),
    .sig(a_sig_w),
    .is_zero(a_zero_w),
    .is_inf(a_inf_w),
    .is_nan(a_nan_w)
);

fp_unpack u_unpack_b (
    .operand(b),
    .sign(b_sign_raw_w),
    .exp(b_exp_w),
    .frac(b_frac_w),
    .exp_eff(b_exp_eff_w),
    .sig(b_sig_w),
    .is_zero(b_zero_w),
    .is_inf(b_inf_w),
    .is_nan(b_nan_w)
);

assign b_sign_eff_w = b_sign_raw_w ^ add_sub;

fp_special u_special (
    .a_sign(a_sign_w),
    .a_exp(a_exp_w),
    .a_frac(a_frac_w),
    .a_zero(a_zero_w),
    .a_inf(a_inf_w),
    .a_nan(a_nan_w),
    .b_sign(b_sign_eff_w),
    .b_exp(b_exp_w),
    .b_frac(b_frac_w),
    .b_zero(b_zero_w),
    .b_inf(b_inf_w),
    .b_nan(b_nan_w),
    .special_valid(special_valid_w),
    .special_result(special_result_w)
);

/* Stage 1 pipeline registers */
reg        s1_valid;
reg        s1_special_valid;
reg [31:0] s1_special_result;
reg        s1_a_sign;
reg [7:0]  s1_a_exp_eff;
reg [23:0] s1_a_sig;
reg        s1_b_sign;
reg [7:0]  s1_b_exp_eff;
reg [23:0] s1_b_sig;

/* -------------------------------------------------------------------------
 * Stage 2 combinational: exponent alignment
 * ---------------------------------------------------------------------- */
wire        align_large_sign_w;
wire        align_small_sign_w;
wire [7:0]  align_large_exp_w;
wire [26:0] align_large_sig_w;
wire [26:0] align_small_sig_w;

fp_align u_align (
    .a_sign(s1_a_sign),
    .a_exp(s1_a_exp_eff),
    .a_sig(s1_a_sig),
    .b_sign(s1_b_sign),
    .b_exp(s1_b_exp_eff),
    .b_sig(s1_b_sig),
    .large_sign(align_large_sign_w),
    .small_sign(align_small_sign_w),
    .large_exp(align_large_exp_w),
    .large_sig(align_large_sig_w),
    .small_sig(align_small_sig_w)
);

/* Stage 2 pipeline registers */
reg        s2_valid;
reg        s2_special_valid;
reg [31:0] s2_special_result;
reg        s2_large_sign;
reg        s2_small_sign;
reg [7:0]  s2_large_exp;
reg [26:0] s2_large_sig;
reg [26:0] s2_small_sig;

/* -------------------------------------------------------------------------
 * Stage 3 combinational: add/subtract aligned significands
 * ---------------------------------------------------------------------- */
wire        addsub_sign_w;
wire [7:0]  addsub_exp_w;
wire [27:0] addsub_mant_w;

fp_addsub u_addsub (
    .large_sign(s2_large_sign),
    .small_sign(s2_small_sign),
    .large_exp(s2_large_exp),
    .large_sig(s2_large_sig),
    .small_sig(s2_small_sig),
    .result_sign(addsub_sign_w),
    .result_exp(addsub_exp_w),
    .result_mant(addsub_mant_w)
);

/* Stage 3 pipeline registers */
reg        s3_valid;
reg        s3_special_valid;
reg [31:0] s3_special_result;
reg        s3_sign;
reg [7:0]  s3_exp;
reg [27:0] s3_mant;

/* -------------------------------------------------------------------------
 * Stage 4 combinational: normalize, round-to-nearest-even, pack
 * ---------------------------------------------------------------------- */
wire [31:0] packed_result_w;

fp_normalize_round_pack u_norm_round_pack (
    .special_valid(s3_special_valid),
    .special_result(s3_special_result),
    .sign(s3_sign),
    .exp(s3_exp),
    .mant(s3_mant),
    .result(packed_result_w)
);

/* Stage 4 pipeline registers */
reg        s4_valid;
reg [31:0] s4_result;

/* Output registers */
reg [31:0] result_r;
reg        valid_out_r;

assign result = result_r;
assign valid_out = valid_out_r;

/* Core 4-stage pipeline */
always @(posedge clk) begin
    if (rst) begin
        s1_valid          <= 1'b0;
        s1_special_valid  <= 1'b0;
        s1_special_result <= 32'b0;
        s1_a_sign         <= 1'b0;
        s1_a_exp_eff      <= 8'b0;
        s1_a_sig          <= 24'b0;
        s1_b_sign         <= 1'b0;
        s1_b_exp_eff      <= 8'b0;
        s1_b_sig          <= 24'b0;

        s2_valid          <= 1'b0;
        s2_special_valid  <= 1'b0;
        s2_special_result <= 32'b0;
        s2_large_sign     <= 1'b0;
        s2_small_sign     <= 1'b0;
        s2_large_exp      <= 8'b0;
        s2_large_sig      <= 27'b0;
        s2_small_sig      <= 27'b0;

        s3_valid          <= 1'b0;
        s3_special_valid  <= 1'b0;
        s3_special_result <= 32'b0;
        s3_sign           <= 1'b0;
        s3_exp            <= 8'b0;
        s3_mant           <= 28'b0;

        s4_valid          <= 1'b0;
        s4_result         <= 32'b0;
    end else begin
        /* Stage 1 */
        s1_valid          <= valid_in;
        s1_special_valid  <= special_valid_w;
        s1_special_result <= special_result_w;
        s1_a_sign         <= a_sign_w;
        s1_a_exp_eff      <= a_exp_eff_w;
        s1_a_sig          <= a_sig_w;
        s1_b_sign         <= b_sign_eff_w;
        s1_b_exp_eff      <= b_exp_eff_w;
        s1_b_sig          <= b_sig_w;

        /* Stage 2 */
        s2_valid          <= s1_valid;
        s2_special_valid  <= s1_special_valid;
        s2_special_result <= s1_special_result;
        s2_large_sign     <= align_large_sign_w;
        s2_small_sign     <= align_small_sign_w;
        s2_large_exp      <= align_large_exp_w;
        s2_large_sig      <= align_large_sig_w;
        s2_small_sig      <= align_small_sig_w;

        /* Stage 3 */
        s3_valid          <= s2_valid;
        s3_special_valid  <= s2_special_valid;
        s3_special_result <= s2_special_result;
        s3_sign           <= addsub_sign_w;
        s3_exp            <= addsub_exp_w;
        s3_mant           <= addsub_mant_w;

        /* Stage 4 */
        s4_valid          <= s3_valid;
        s4_result         <= packed_result_w;
    end
end

/* Optional output delay to make externally visible latency parameterizable.
 * For LATENCY=5, this adds one register after the 4 computation stages.
 * The result register holds its last valid value when valid_out is low,
 * matching the supplied testbench sampling style.
 */
generate
if (EXTRA_DELAY == 0) begin : gen_no_extra_delay
    always @(posedge clk) begin
        if (rst) begin
            result_r    <= 32'b0;
            valid_out_r <= 1'b0;
        end else begin
            valid_out_r <= s4_valid;
            if (s4_valid)
                result_r <= s4_result;
        end
    end
end else begin : gen_extra_delay
    reg [31:0] delay_result [0:EXTRA_DELAY-1];
    reg [EXTRA_DELAY-1:0] delay_valid;
    integer i;

    always @(posedge clk) begin
        if (rst) begin
            valid_out_r <= 1'b0;
            result_r    <= 32'b0;
            delay_valid <= {EXTRA_DELAY{1'b0}};
            for (i = 0; i < EXTRA_DELAY; i = i + 1)
                delay_result[i] <= 32'b0;
        end else begin
            delay_valid[0]  <= s4_valid;
            delay_result[0] <= s4_result;

            for (i = 1; i < EXTRA_DELAY; i = i + 1) begin
                delay_valid[i]  <= delay_valid[i-1];
                delay_result[i] <= delay_result[i-1];
            end

            valid_out_r <= delay_valid[EXTRA_DELAY-1];
            if (delay_valid[EXTRA_DELAY-1])
                result_r <= delay_result[EXTRA_DELAY-1];
        end
    end
end
endgenerate

endmodule