`timescale 1ns/1ps

module bpf_mac_sum #(
    parameter TAP_CNT = 101,
    parameter PROD_W  = 64,
    parameter ACC_W   = 64
) (
    input  signed [PROD_W*TAP_CNT-1:0] products,
    output reg signed [ACC_W-1:0]      sum
);

    integer i;

    always @* begin
        sum = {ACC_W{1'b0}};
        for (i = 0; i < TAP_CNT; i = i + 1)
            sum = sum + $signed(products[(i*PROD_W) +: PROD_W]);
    end

endmodule