`timescale 1ns/1ps

module harris_grad_products #(
    parameter GRAD_W = 16,
    parameter PROD_W = 32
) (
    input  signed [GRAD_W-1:0] gx,
    input  signed [GRAD_W-1:0] gy,
    output signed [PROD_W-1:0] ix2,
    output signed [PROD_W-1:0] iy2,
    output signed [PROD_W-1:0] ixy
);

    localparam NAT_PROD_W = 2 * GRAD_W;

    wire signed [NAT_PROD_W-1:0] gx_sq_full;
    wire signed [NAT_PROD_W-1:0] gy_sq_full;
    wire signed [NAT_PROD_W-1:0] gx_gy_full;

    assign gx_sq_full = gx * gx;
    assign gy_sq_full = gy * gy;
    assign gx_gy_full = gx * gy;

    generate
        if (PROD_W >= NAT_PROD_W) begin : gen_extend_outputs
            assign ix2 = {{(PROD_W-NAT_PROD_W){gx_sq_full[NAT_PROD_W-1]}}, gx_sq_full};
            assign iy2 = {{(PROD_W-NAT_PROD_W){gy_sq_full[NAT_PROD_W-1]}}, gy_sq_full};
            assign ixy = {{(PROD_W-NAT_PROD_W){gx_gy_full[NAT_PROD_W-1]}}, gx_gy_full};
        end else begin : gen_truncate_outputs
            assign ix2 = gx_sq_full[PROD_W-1:0];
            assign iy2 = gy_sq_full[PROD_W-1:0];
            assign ixy = gx_gy_full[PROD_W-1:0];
        end
    endgenerate

endmodule