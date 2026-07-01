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
wire zero_a;
wire zero_b;
wire inf_a;
wire inf_b;
wire nan_a;
wire nan_b;

wire sign_b_eff;
wire special_valid;
wire [31:0] special_result;
wire [31:0] core_result;
wire [31:0] packed_result;
wire [31:0] next_result;

reg [31:0] result_pipe [0:LATENCY-1];
reg [LATENCY-1:0] valid_pipe;

integer i;

fp_unpack u_unpack_a (
    .operand(a),
    .sign(sign_a),
    .exponent(exp_a),
    .fraction(frac_a),
    .is_zero(zero_a),
    .is_inf(inf_a),
    .is_nan(nan_a)
);

fp_unpack u_unpack_b (
    .operand(b),
    .sign(sign_b_raw),
    .exponent(exp_b),
    .fraction(frac_b),
    .is_zero(zero_b),
    .is_inf(inf_b),
    .is_nan(nan_b)
);

assign sign_b_eff = sign_b_raw ^ add_sub;

fp_special_cases u_special (
    .sign_a(sign_a),
    .sign_b(sign_b_eff),
    .is_zero_a(zero_a),
    .is_zero_b(zero_b),
    .is_inf_a(inf_a),
    .is_inf_b(inf_b),
    .is_nan_a(nan_a),
    .is_nan_b(nan_b),
    .special_valid(special_valid),
    .special_result(special_result)
);

fp_add_core u_core (
    .sign_a(sign_a),
    .sign_b(sign_b_eff),
    .exp_a(exp_a),
    .exp_b(exp_b),
    .frac_a(frac_a),
    .frac_b(frac_b),
    .is_zero_a(zero_a),
    .is_zero_b(zero_b),
    .result(core_result)
);

fp_result_pack u_pack (
    .special_valid(special_valid),
    .special_result(special_result),
    .normal_result(core_result),
    .result(packed_result)
);

assign next_result = packed_result;
assign result = result_pipe[LATENCY-1];
assign valid_out = valid_pipe[LATENCY-1];

always @(posedge clk) begin
    if (rst) begin
        valid_pipe <= {LATENCY{1'b0}};
        for (i = 0; i < LATENCY; i = i + 1) begin
            result_pipe[i] <= 32'h00000000;
        end
    end else begin
        valid_pipe[0] <= valid_in;
        result_pipe[0] <= next_result;

        for (i = 1; i < LATENCY; i = i + 1) begin
            valid_pipe[i] <= valid_pipe[i-1];
            result_pipe[i] <= result_pipe[i-1];
        end
    end
end

endmodule