`timescale 1ns/1ps

module gs2x2_result_select #(
    parameter DATA_WIDTH = 32
)(
    input exact_valid,
    input signed [DATA_WIDTH-1:0] exact_x1,
    input signed [DATA_WIDTH-1:0] exact_x2,
    input signed [DATA_WIDTH-1:0] iter_x1,
    input signed [DATA_WIDTH-1:0] iter_x2,
    output signed [DATA_WIDTH-1:0] x1_out,
    output signed [DATA_WIDTH-1:0] x2_out
);

    assign x1_out = exact_valid ? exact_x1 : iter_x1;
    assign x2_out = exact_valid ? exact_x2 : iter_x2;

endmodule