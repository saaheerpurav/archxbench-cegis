`timescale 1ns/1ps

module gs2x2_fixed_mul #(
    parameter DATA_WIDTH = 32,
    parameter FRAC = 16
)(
    input  signed [DATA_WIDTH-1:0] lhs,
    input  signed [DATA_WIDTH-1:0] rhs,
    output signed [DATA_WIDTH-1:0] product
);

    wire signed [(2*DATA_WIDTH)-1:0] full_product;

    assign full_product = lhs * rhs;
    assign product = full_product >>> FRAC;

endmodule