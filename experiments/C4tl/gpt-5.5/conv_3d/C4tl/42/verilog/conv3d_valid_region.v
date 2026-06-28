`timescale 1ns/1ps

module conv3d_valid_region #(
    parameter K1 = 3,
    parameter K2 = 3,
    parameter K3 = 3,
    parameter D  = 8,
    parameter H  = 64,
    parameter W  = 64
) (
    input  [31:0] depth_idx,
    input  [31:0] row_idx,
    input  [31:0] col_idx,
    output        valid_region
);

    /*
     * A valid-region output is produced only after the streaming traversal has
     * advanced far enough in each dimension for the full causal 3D convolution
     * window to exist.
     *
     * For zero-based coordinates:
     *   first valid depth = K1 - 1
     *   first valid row   = K2 - 1
     *   first valid col   = K3 - 1
     *
     * Coordinates outside the declared volume are never valid.
     */

    localparam [31:0] DEPTH_FIRST_VALID = (K1 > 0) ? (K1 - 1) : 0;
    localparam [31:0] ROW_FIRST_VALID   = (K2 > 0) ? (K2 - 1) : 0;
    localparam [31:0] COL_FIRST_VALID   = (K3 > 0) ? (K3 - 1) : 0;

    localparam        KERNEL_NONZERO =
        (K1 > 0) &&
        (K2 > 0) &&
        (K3 > 0);

    localparam        KERNEL_FITS =
        (K1 <= D) &&
        (K2 <= H) &&
        (K3 <= W);

    assign valid_region =
        KERNEL_NONZERO &&
        KERNEL_FITS &&
        (depth_idx >= DEPTH_FIRST_VALID) &&
        (row_idx   >= ROW_FIRST_VALID) &&
        (col_idx   >= COL_FIRST_VALID) &&
        (depth_idx <  D) &&
        (row_idx   <  H) &&
        (col_idx   <  W);

endmodule