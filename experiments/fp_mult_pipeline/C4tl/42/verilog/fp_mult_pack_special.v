`timescale 1ns/1ps

module fp_mult_pack_special (
    input sign,
    input [23:0] sig,
    input signed [9:0] exp_in,
    input zero_a,
    input zero_b,
    input inf_a,
    input inf_b,
    input nan_a,
    input nan_b,
    output [31:0] result
);

localparam [7:0] MAX_EXP = 8'hFF;
localparam [31:0] CANONICAL_NAN = 32'h7FC00000;

wire invalid_zero_inf = (zero_a && inf_b) || (zero_b && inf_a);
wire any_zero = zero_a || zero_b;
wire any_inf = inf_a || inf_b;
wire any_nan = nan_a || nan_b;

reg [31:0] result_r;

always @(*) begin
    if (any_nan || invalid_zero_inf) begin
        result_r = CANONICAL_NAN;
    end else if (any_inf) begin
        result_r = {sign, MAX_EXP, 23'b0};
    end else if (any_zero) begin
        result_r = {sign, 31'b0};
    end else if (exp_in >= 10'sd255) begin
        result_r = {sign, MAX_EXP, 23'b0};
    end else if (exp_in >= 10'sd1) begin
        result_r = {sign, exp_in[7:0], sig[22:0]};
    end else begin
        result_r = {sign, 31'b0};
    end
end

assign result = result_r;

endmodule