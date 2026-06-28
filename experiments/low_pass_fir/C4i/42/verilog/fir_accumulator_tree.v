`timescale 1ns/1ps

module fir_accumulator_tree #(
    parameter PAIR_CNT = 50,
    parameter PROD_W   = 64
) (
    products,
    center_product,
    acc_out
);

    input      [PROD_W*PAIR_CNT-1:0] products;
    input signed [PROD_W-1:0]        center_product;
    output reg signed [PROD_W-1:0]   acc_out;

    integer i;
    reg signed [PROD_W-1:0] product_term;

    always @* begin
        acc_out = center_product;

        for (i = 0; i < PAIR_CNT; i = i + 1) begin
            product_term = products[i*PROD_W +: PROD_W];
            acc_out = acc_out + product_term;
        end
    end

endmodule