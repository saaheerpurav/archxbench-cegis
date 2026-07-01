`timescale 1ns/1ps

module conv3d_window_valid #(
    parameter K1 = 3,
    parameter K2 = 3,
    parameter K3 = 3,
    parameter D  = 8,
    parameter H  = 64,
    parameter W  = 64
) (
    input         valid_in,
    input  [31:0] x_pos,
    input  [31:0] y_pos,
    input  [31:0] z_pos,
    output        window_valid
);

    assign window_valid = valid_in &&
                          (x_pos >= K3 - 1) &&
                          (y_pos >= K2 - 1) &&
                          (z_pos >= K1 - 1) &&
                          (x_pos < W) &&
                          (y_pos < H) &&
                          (z_pos < D);

endmodule