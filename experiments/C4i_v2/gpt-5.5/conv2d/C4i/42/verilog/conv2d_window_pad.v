`timescale 1ns/1ps

module conv2d_window_pad #(
    parameter DATA_W      = 8,
    parameter IMG_WIDTH   = 64,
    parameter KERNEL_SIZE = 3
) (
    input  [KERNEL_SIZE*KERNEL_SIZE*DATA_W-1:0] raw_window,
    input  [31:0]                               out_row,
    input  [31:0]                               out_col,
    output reg [KERNEL_SIZE*KERNEL_SIZE*DATA_W-1:0] padded_window
);

    localparam integer RADIUS = KERNEL_SIZE / 2;

    /*
     * This design/test uses a square image.  The module has no separate
     * IMG_HEIGHT parameter, so IMG_WIDTH is also used as the row bound.
     */
    localparam [32:0] IMG_WIDTH_EXT  = IMG_WIDTH;
    localparam [32:0] IMG_HEIGHT_EXT = IMG_WIDTH;
    localparam [32:0] RADIUS_EXT     = RADIUS;

    integer kr;
    integer kc;
    integer bit_i;
    integer win_index;

    reg [32:0] row_tap_sum;
    reg [32:0] col_tap_sum;
    reg        coord_known;
    reg        tap_valid;

    reg [DATA_W-1:0] raw_pix;

    /*
     * Return 1 only when all coordinate bits are known 0/1.
     */
    function is_known32;
        input [31:0] value;
        begin
            is_known32 = ((^value) !== 1'bx);
        end
    endfunction

    /*
     * Convert a possibly 4-state simulation pixel into a guaranteed 2-state
     * value.  Known 1 bits remain 1; known 0, X, and Z bits become 0.
     */
    function [DATA_W-1:0] clean_pixel;
        input [DATA_W-1:0] pix;
        integer i;
        begin
            for (i = 0; i < DATA_W; i = i + 1) begin
                clean_pixel[i] = (pix[i] === 1'b1) ? 1'b1 : 1'b0;
            end
        end
    endfunction

    always @* begin
        padded_window = {(KERNEL_SIZE*KERNEL_SIZE*DATA_W){1'b0}};

        coord_known = is_known32(out_row) && is_known32(out_col);

        for (kr = 0; kr < KERNEL_SIZE; kr = kr + 1) begin
            for (kc = 0; kc < KERNEL_SIZE; kc = kc + 1) begin
                win_index = ((kr * KERNEL_SIZE) + kc) * DATA_W;
                raw_pix   = raw_window[win_index +: DATA_W];

                tap_valid = 1'b0;

                if (coord_known) begin
                    /*
                     * A tap coordinate is:
                     *
                     *   rr = out_row + kr - RADIUS
                     *   cc = out_col + kc - RADIUS
                     *
                     * Avoid signed subtraction by checking the equivalent
                     * unsigned bounds:
                     *
                     *   out_row + kr >= RADIUS
                     *   out_row + kr <  IMG_HEIGHT + RADIUS
                     *   out_col + kc >= RADIUS
                     *   out_col + kc <  IMG_WIDTH  + RADIUS
                     */
                    row_tap_sum = {1'b0, out_row} + kr;
                    col_tap_sum = {1'b0, out_col} + kc;

                    if ((row_tap_sum >= RADIUS_EXT) &&
                        (row_tap_sum <  (IMG_HEIGHT_EXT + RADIUS_EXT)) &&
                        (col_tap_sum >= RADIUS_EXT) &&
                        (col_tap_sum <  (IMG_WIDTH_EXT  + RADIUS_EXT))) begin
                        tap_valid = 1'b1;
                    end
                end

                if (tap_valid) begin
                    padded_window[win_index +: DATA_W] = clean_pixel(raw_pix);
                end
            end
        end
    end

endmodule