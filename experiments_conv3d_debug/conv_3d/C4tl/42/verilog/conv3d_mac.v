`timescale 1ns/1ps

module conv3d_mac #(
    parameter K1 = 3,
    parameter K2 = 3,
    parameter K3 = 3,
    parameter DATA_W = 8,
    parameter ACC_W = 28
) (
    input  [K1*K2*K3*DATA_W-1:0] window,
    input  [K1*K2*K3*DATA_W-1:0] kernel,
    output reg [ACC_W-1:0] sum
);
    localparam KTOT = K1 * K2 * K3;

    integer i;
    reg [DATA_W-1:0] voxel_i;
    reg [DATA_W-1:0] kernel_i;
    reg [2*DATA_W-1:0] product_i;

    always @(*) begin
        sum = {ACC_W{1'b0}};

        for (i = 0; i < KTOT; i = i + 1) begin
            voxel_i  = window[i*DATA_W +: DATA_W];
            kernel_i = kernel[i*DATA_W +: DATA_W];
            product_i = voxel_i * kernel_i;
            sum = sum + product_i;
        end
    end

endmodule