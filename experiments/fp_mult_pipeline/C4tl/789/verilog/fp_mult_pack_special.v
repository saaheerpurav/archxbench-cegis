`timescale 1ns/1ps

module fp_mult_pack_special (
    input sign,
    input signed [10:0] exp_in,
    input [23:0] mantissa,
    input zero_a,
    input zero_b,
    input inf_a,
    input inf_b,
    input nan_a,
    input nan_b,
    output [31:0] result
);

reg [31:0] result_reg;

assign result = result_reg;

always @(*) begin
    if (nan_a || nan_b || ((inf_a || inf_b) && (zero_a || zero_b))) begin
        result_reg = 32'h7FC00000;
    end else if (inf_a || inf_b) begin
        result_reg = {sign, 8'hFF, 23'b0};
    end else if (zero_a || zero_b) begin
        result_reg = {sign, 31'b0};
    end else if (exp_in >= 11'sd255) begin
        result_reg = {sign, 8'hFF, 23'b0};
    end else if (exp_in <= 11'sd0) begin
        result_reg = {sign, 31'b0};
    end else begin
        result_reg = {sign, exp_in[7:0], mantissa[22:0]};
    end
end

endmodule