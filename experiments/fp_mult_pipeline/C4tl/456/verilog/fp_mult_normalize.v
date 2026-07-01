`timescale 1ns/1ps

module fp_mult_normalize (
    input [47:0] product,
    input signed [10:0] exp_in,
    output [23:0] mantissa,
    output guard_bit,
    output round_bit,
    output sticky_bit,
    output signed [10:0] exp_out
);
    reg [47:0] normalized_product;
    reg signed [10:0] normalized_exp;
    reg [5:0] leading_pos;
    reg found_one;
    integer i;

    always @(*) begin
        normalized_product = 48'b0;
        normalized_exp = exp_in;
        leading_pos = 6'd0;
        found_one = 1'b0;

        for (i = 47; i >= 0; i = i - 1) begin
            if (!found_one && product[i]) begin
                leading_pos = i[5:0];
                found_one = 1'b1;
            end
        end

        if (!found_one) begin
            normalized_product = 48'b0;
            normalized_exp = exp_in;
        end else if (leading_pos == 6'd47) begin
            normalized_product = product >> 1;
            normalized_exp = exp_in + 11'sd1;
        end else if (leading_pos < 6'd46) begin
            normalized_product = product << (6'd46 - leading_pos);
            normalized_exp = exp_in - $signed({5'b0, (6'd46 - leading_pos)});
        end else begin
            normalized_product = product;
            normalized_exp = exp_in;
        end
    end

    assign mantissa = normalized_product[46:23];
    assign guard_bit = normalized_product[22];
    assign round_bit = normalized_product[21];
    assign sticky_bit = |normalized_product[20:0];
    assign exp_out = normalized_exp;
endmodule