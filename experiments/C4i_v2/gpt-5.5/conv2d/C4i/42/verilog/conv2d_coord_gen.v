`timescale 1ns/1ps

module conv2d_coord_gen #(
    parameter IMG_WIDTH   = 64,
    parameter KERNEL_SIZE = 3
) (
    input             valid_in,
    input      [31:0] pixel_count,
    output reg [31:0] in_row,
    output reg [31:0] in_col,
    output reg [31:0] out_row,
    output reg [31:0] out_col,
    output reg        window_valid
);

    localparam integer RADIUS        = KERNEL_SIZE / 2;
    localparam integer COORD_LATENCY = (RADIUS * IMG_WIDTH) + RADIUS;
    localparam integer FILL_OFFSET   = KERNEL_SIZE - 1;

    reg [31:0] out_index;

    always @* begin
        /*
         * Current input pixel coordinates.
         * pixel_count is the raster-order index of the pixel currently being
         * accepted by the first pipeline stage.
         */
        in_row = pixel_count / IMG_WIDTH;
        in_col = pixel_count % IMG_WIDTH;

        /*
         * The output coordinate is the center of the KxK window whose newest
         * sample is the current input pixel.  This coordinate is delayed from
         * the input coordinate by RADIUS rows and RADIUS columns.
         */
        if (pixel_count >= COORD_LATENCY) begin
            out_index = pixel_count - COORD_LATENCY;
        end else begin
            out_index = 32'd0;
        end

        out_row = out_index / IMG_WIDTH;
        out_col = out_index % IMG_WIDTH;

        /*
         * The raw stencil window is valid only after KERNEL_SIZE-1 previous
         * rows and KERNEL_SIZE-1 previous columns have been received.
         *
         * The previous implementation asserted this at COORD_LATENCY, which
         * is correct for the centered coordinate but too early for the actual
         * line-buffer window contents.  That allowed uninitialized buffer
         * entries to enter the convolution and produced X values.
         */
        window_valid = valid_in &&
                       (in_row >= FILL_OFFSET) &&
                       (in_col >= FILL_OFFSET);
    end

endmodule