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

wire sa, sb;
wire [7:0] ea, eb;
wire [26:0] siga, sigb;
wire a_zero, b_zero, a_inf, b_inf, a_nan, b_nan;

wire special_valid;
wire [31:0] special_result;

wire align_sign_large, align_sign_small;
wire [7:0] align_exp;
wire [26:0] align_sig_large, align_sig_small;

wire add_sign;
wire [7:0] add_exp;
wire [27:0] add_mag;

wire norm_sign;
wire [7:0] norm_exp;
wire [26:0] norm_sig;
wire norm_zero;

wire [31:0] computed_result;
wire [31:0] datapath_result;

fp_unpack u_unpack (
    .a(a),
    .b(b),
    .add_sub(add_sub),
    .sign_a(sa),
    .sign_b(sb),
    .exp_a(ea),
    .exp_b(eb),
    .sig_a(siga),
    .sig_b(sigb),
    .a_zero(a_zero),
    .b_zero(b_zero),
    .a_inf(a_inf),
    .b_inf(b_inf),
    .a_nan(a_nan),
    .b_nan(b_nan)
);

fp_special_cases u_special (
    .sign_a(sa),
    .sign_b(sb),
    .a_zero(a_zero),
    .b_zero(b_zero),
    .a_inf(a_inf),
    .b_inf(b_inf),
    .a_nan(a_nan),
    .b_nan(b_nan),
    .special_valid(special_valid),
    .special_result(special_result)
);

fp_align u_align (
    .sign_a(sa),
    .sign_b(sb),
    .exp_a(ea),
    .exp_b(eb),
    .sig_a(siga),
    .sig_b(sigb),
    .sign_large(align_sign_large),
    .sign_small(align_sign_small),
    .exp_large(align_exp),
    .sig_large(align_sig_large),
    .sig_small(align_sig_small)
);

fp_addsub u_addsub (
    .sign_large(align_sign_large),
    .sign_small(align_sign_small),
    .exp_in(align_exp),
    .sig_large(align_sig_large),
    .sig_small(align_sig_small),
    .sign_out(add_sign),
    .exp_out(add_exp),
    .mag_out(add_mag)
);

fp_normalize u_normalize (
    .sign_in(add_sign),
    .exp_in(add_exp),
    .mag_in(add_mag),
    .sign_out(norm_sign),
    .exp_out(norm_exp),
    .sig_out(norm_sig),
    .is_zero(norm_zero)
);

fp_round_pack u_round_pack (
    .sign_in(norm_sign),
    .exp_in(norm_exp),
    .sig_in(norm_sig),
    .is_zero(norm_zero),
    .result(datapath_result)
);

assign computed_result = special_valid ? special_result : datapath_result;

generate
    if (LATENCY <= 0) begin : gen_no_pipe
        assign result = computed_result;
        assign valid_out = valid_in;
    end else begin : gen_pipe
        reg [31:0] result_pipe [0:LATENCY-1];
        reg [LATENCY-1:0] valid_pipe;
        integer i;

        always @(posedge clk) begin
            if (rst) begin
                valid_pipe <= {LATENCY{1'b0}};
                for (i = 0; i < LATENCY; i = i + 1)
                    result_pipe[i] <= 32'b0;
            end else begin
                valid_pipe[0] <= valid_in;
                result_pipe[0] <= computed_result;
                for (i = 1; i < LATENCY; i = i + 1) begin
                    valid_pipe[i] <= valid_pipe[i-1];
                    result_pipe[i] <= result_pipe[i-1];
                end
            end
        end

        assign result = result_pipe[LATENCY-1];
        assign valid_out = valid_pipe[LATENCY-1];
    end
endgenerate

endmodule