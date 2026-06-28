`timescale 1ns/1ps

module harris_gradient_products #(
    parameter GRAD_W = 16,
    parameter PROD_W = 32
) (
    input  signed [GRAD_W-1:0] gx,
    input  signed [GRAD_W-1:0] gy,
    output        [PROD_W-1:0] ix2,
    output        [PROD_W-1:0] iy2,
    output signed [PROD_W-1:0] ixy
);

    localparam FULL_PROD_W = 2 * GRAD_W;

    wire signed [FULL_PROD_W-1:0] ix2_full;
    wire signed [FULL_PROD_W-1:0] iy2_full;
    wire signed [FULL_PROD_W-1:0] ixy_full;

    assign ix2_full = gx * gx;
    assign iy2_full = gy * gy;
    assign ixy_full = gx * gy;

generate
    if (PROD_W >= FULL_PROD_W) begin : gen_extend_products
        assign ix2 = {{(PROD_W-FULL_PROD_W){1'b0}}, ix2_full};
        assign iy2 = {{(PROD_W-FULL_PROD_W){1'b0}}, iy2_full};
        assign ixy = {{(PROD_W-FULL_PROD_W){ixy_full[FULL_PROD_W-1]}}, ixy_full};
    end else begin : gen_truncate_products
        assign ix2 = ix2_full[PROD_W-1:0];
        assign iy2 = iy2_full[PROD_W-1:0];
        assign ixy = ixy_full[PROD_W-1:0];
    end
endgenerate

endmodule