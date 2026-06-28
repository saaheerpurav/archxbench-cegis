`timescale 1ns/1ps

module conv3d_valid_region_comb #(
    parameter K1 = 3,
    parameter K2 = 3,
    parameter K3 = 3
) (
    input  [31:0] x_cur,
    input  [31:0] y_cur,
    input  [31:0] z_cur,
    input         valid_in,
    output        window_valid
);

    /*
     * Pure-combinational valid-padding region detector for stride-1
     * 3D convolution.
     *
     * Coordinates are zero-based current input voxel coordinates.
     * The current coordinate is interpreted as the trailing corner of
     * the sliding window.
     *
     * Kernel dimension mapping:
     *   K3 -> x / width
     *   K2 -> y / height
     *   K1 -> z / depth
     *
     * A complete valid-padding window exists when:
     *   x_cur >= K3 - 1
     *   y_cur >= K2 - 1
     *   z_cur >= K1 - 1
     */

    localparam [0:0] KERNEL_DIMS_VALID =
        (K1 > 0) && (K2 > 0) && (K3 > 0);

    localparam [31:0] X_MIN = (K3 > 0) ? (K3 - 1) : 32'hFFFFFFFF;
    localparam [31:0] Y_MIN = (K2 > 0) ? (K2 - 1) : 32'hFFFFFFFF;
    localparam [31:0] Z_MIN = (K1 > 0) ? (K1 - 1) : 32'hFFFFFFFF;

    assign window_valid =
        valid_in &&
        KERNEL_DIMS_VALID &&
        (x_cur >= X_MIN) &&
        (y_cur >= Y_MIN) &&
        (z_cur >= Z_MIN);

endmodule