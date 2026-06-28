`timescale 1ns/1ps

module conv3d_window_formatter_comb #(
    parameter K1 = 3,
    parameter K2 = 3,
    parameter K3 = 3,
    parameter DATA_W = 8
) (
    input  [DATA_W-1:0] voxel_in,
    output reg [K1*K2*K3*DATA_W-1:0] window_flat
);

    localparam integer NUM_TAPS = K1 * K2 * K3;

    integer i;

    always @* begin
        window_flat = {K1*K2*K3*DATA_W{1'b0}};

        for (i = 0; i < NUM_TAPS; i = i + 1) begin
            window_flat[i*DATA_W +: DATA_W] = voxel_in;
        end
    end

endmodule