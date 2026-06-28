`timescale 1ns/1ps

module conv3d_tap_addr #(
    parameter K1 = 3,
    parameter K2 = 3,
    parameter K3 = 3,
    parameter D  = 8,
    parameter H  = 64,
    parameter W  = 64,
    parameter TD = 0,
    parameter TH = 0,
    parameter TW = 0
) (
    input  [31:0] depth_idx,
    input  [31:0] row_idx,
    input  [31:0] col_idx,
    output        in_range,
    output        is_current,
    output [31:0] addr
);

    /*
     * Tap offsets relative to the current streamed voxel.
     *
     * The current voxel is the newest sample in the sliding window and
     * corresponds to tap coordinate:
     *
     *   TD = K1-1, TH = K2-1, TW = K3-1
     *
     * Earlier taps therefore refer to older buffered voxels.
     */
    localparam [31:0] DEPTH_OFF = K1 - 1 - TD;
    localparam [31:0] ROW_OFF   = K2 - 1 - TH;
    localparam [31:0] COL_OFF   = K3 - 1 - TW;

    localparam [31:0] D_U = D;
    localparam [31:0] H_U = H;
    localparam [31:0] W_U = W;

    wire depth_ge_off;
    wire row_ge_off;
    wire col_ge_off;

    wire [31:0] src_depth;
    wire [31:0] src_row;
    wire [31:0] src_col;

    wire depth_in_range;
    wire row_in_range;
    wire col_in_range;

    wire [31:0] plane_size;
    wire [31:0] linear_addr;

    assign depth_ge_off = depth_idx >= DEPTH_OFF;
    assign row_ge_off   = row_idx   >= ROW_OFF;
    assign col_ge_off   = col_idx   >= COL_OFF;

    assign src_depth = depth_idx - DEPTH_OFF;
    assign src_row   = row_idx   - ROW_OFF;
    assign src_col   = col_idx   - COL_OFF;

    assign depth_in_range = depth_ge_off && (src_depth < D_U);
    assign row_in_range   = row_ge_off   && (src_row   < H_U);
    assign col_in_range   = col_ge_off   && (src_col   < W_U);

    assign in_range = depth_in_range && row_in_range && col_in_range;

    /*
     * This tap maps directly to the live input voxel only when all offsets
     * are zero.  In all other cases the value must come from buffered storage.
     */
    assign is_current =
        in_range &&
        (DEPTH_OFF == 32'd0) &&
        (ROW_OFF   == 32'd0) &&
        (COL_OFF   == 32'd0);

    /*
     * Flattened address in depth-major order:
     *
     *   addr = depth * H * W + row * W + col
     */
    assign plane_size  = H_U * W_U;
    assign linear_addr = (src_depth * plane_size) + (src_row * W_U) + src_col;

    assign addr = in_range ? linear_addr : 32'd0;

endmodule