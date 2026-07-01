`timescale 1ns/1ps

module fp_result_pack (
    input special_valid,
    input [31:0] special_result,
    input [31:0] normal_result,
    output [31:0] result
);

assign result = special_valid ? special_result : normal_result;

endmodule