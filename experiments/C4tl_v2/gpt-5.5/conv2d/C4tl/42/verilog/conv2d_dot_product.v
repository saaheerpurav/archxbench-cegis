`timescale 1ns/1ps

module conv2d_dot_product #(
    parameter DATA_W      = 8,
    parameter KERNEL_SIZE = 3,
    parameter COEFF_W     = 16,
    parameter ACC_W       = 32
) (
    input  [KERNEL_SIZE*KERNEL_SIZE*DATA_W-1:0]   window_flat,
    input  [KERNEL_SIZE*KERNEL_SIZE*COEFF_W-1:0]  coeffs_flat,
    output reg signed [ACC_W-1:0]                 acc_out
);

    localparam integer KERNEL_ELEMS = KERNEL_SIZE * KERNEL_SIZE;

    integer i;

    reg [DATA_W-1:0]              pix_val;
    reg signed [COEFF_W-1:0]      coeff_val;
    reg signed [ACC_W-1:0]        product_ext;

    always @* begin
        acc_out = {ACC_W{1'b0}};

        for (i = 0; i < KERNEL_ELEMS; i = i + 1) begin
            pix_val   = window_flat[(i*DATA_W) +: DATA_W];
            coeff_val = coeffs_flat[(i*COEFF_W) +: COEFF_W];

            product_ext = $signed({1'b0, pix_val}) * coeff_val;

            acc_out = acc_out + product_ext;
        end
    end

endmodule