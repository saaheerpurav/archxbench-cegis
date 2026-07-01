`timescale 1ns/1ps

module fp_special_cases (
    input        a_sign,
    input [7:0]  a_exp,
    input [22:0] a_frac,
    input        a_zero,
    input        a_inf,
    input        a_nan,
    input        b_sign,
    input [7:0]  b_exp,
    input [22:0] b_frac,
    input        b_zero,
    input        b_inf,
    input        b_nan,
    output reg        special_valid,
    output reg [31:0] special_result
);

always @* begin
    special_valid = 1'b0;
    special_result = 32'h00000000;

    if (a_nan) begin
        special_valid = 1'b1;
        special_result = {1'b0, 8'hff, 1'b1, a_frac[21:0]};
    end else if (b_nan) begin
        special_valid = 1'b1;
        special_result = {1'b0, 8'hff, 1'b1, b_frac[21:0]};
    end else if (a_inf && b_inf && (a_sign != b_sign)) begin
        special_valid = 1'b1;
        special_result = 32'h7fc00000;
    end else if (a_inf) begin
        special_valid = 1'b1;
        special_result = {a_sign, 8'hff, 23'h000000};
    end else if (b_inf) begin
        special_valid = 1'b1;
        special_result = {b_sign, 8'hff, 23'h000000};
    end else if (a_zero && b_zero) begin
        special_valid = 1'b1;
        special_result = ((a_sign & b_sign) ? 32'h80000000 : 32'h00000000);
    end else if (a_zero) begin
        special_valid = 1'b1;
        special_result = {b_sign, b_exp, b_frac};
    end else if (b_zero) begin
        special_valid = 1'b1;
        special_result = {a_sign, a_exp, a_frac};
    end
end

endmodule