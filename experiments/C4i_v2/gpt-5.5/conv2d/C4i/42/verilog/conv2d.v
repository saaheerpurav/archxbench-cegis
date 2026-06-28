`timescale 1ns/1ps

module conv2d #(
    parameter DATA_W      = 8,
    parameter IMG_WIDTH   = 64,
    parameter KERNEL_SIZE = 3,
    parameter GAIN_W      = 4
) (
    input                          clk,
    input                          rst,
    input                          valid_in,
    input      [DATA_W-1:0]        pixel_in,
    output                         valid_out,
    output     [DATA_W+GAIN_W-1:0] pixel_out
);

    localparam K2       = KERNEL_SIZE*KERNEL_SIZE;
    localparam OUT_W    = DATA_W + GAIN_W;
    localparam COEFF_W  = 16;
    localparam ACC_W    = OUT_W + 16;
    localparam BUF_PIX  = KERNEL_SIZE * IMG_WIDTH;
    localparam BUF_W    = BUF_PIX * DATA_W;

    reg [31:0] pixel_count;
    reg [BUF_W-1:0] linebuf_flat;

    wire [31:0] in_row_w;
    wire [31:0] in_col_w;
    wire [31:0] out_row_w;
    wire [31:0] out_col_w;
    wire        coord_valid_w;

    wire [K2*DATA_W-1:0]   raw_window_w;
    wire [K2*DATA_W-1:0]   padded_window_w;
    wire [K2*COEFF_W-1:0]  coeffs_w;
    wire [OUT_W-1:0]       dot_out_w;

    integer wr_row;
    integer wr_col;
    integer wr_bit;

    conv2d_coord_gen #(
        .IMG_WIDTH(IMG_WIDTH),
        .KERNEL_SIZE(KERNEL_SIZE)
    ) u_coord_gen (
        .valid_in(valid_in),
        .pixel_count(pixel_count),
        .in_row(in_row_w),
        .in_col(in_col_w),
        .out_row(out_row_w),
        .out_col(out_col_w),
        .window_valid(coord_valid_w)
    );

    conv2d_linebuf_read #(
        .DATA_W(DATA_W),
        .IMG_WIDTH(IMG_WIDTH),
        .KERNEL_SIZE(KERNEL_SIZE)
    ) u_linebuf_read (
        .linebuf_flat(linebuf_flat),
        .valid_in(valid_in),
        .pixel_count(pixel_count),
        .current_pixel(pixel_in),
        .in_row(in_row_w),
        .in_col(in_col_w),
        .out_row(out_row_w),
        .out_col(out_col_w),
        .raw_window(raw_window_w)
    );

    conv2d_window_pad #(
        .DATA_W(DATA_W),
        .IMG_WIDTH(IMG_WIDTH),
        .KERNEL_SIZE(KERNEL_SIZE)
    ) u_window_pad (
        .raw_window(raw_window_w),
        .out_row(out_row_w),
        .out_col(out_col_w),
        .padded_window(padded_window_w)
    );

    conv2d_coeff_rom #(
        .KERNEL_SIZE(KERNEL_SIZE),
        .COEFF_W(COEFF_W)
    ) u_coeff_rom (
        .coeffs_flat(coeffs_w)
    );

    conv2d_dot_product #(
        .DATA_W(DATA_W),
        .KERNEL_SIZE(KERNEL_SIZE),
        .GAIN_W(GAIN_W),
        .COEFF_W(COEFF_W),
        .ACC_W(ACC_W)
    ) u_dot_product (
        .window_flat(padded_window_w),
        .coeffs_flat(coeffs_w),
        .pixel_out(dot_out_w)
    );

    assign valid_out = coord_valid_w;
    assign pixel_out = dot_out_w;

    always @(posedge clk) begin
        if (rst) begin
            pixel_count  <= 32'd0;
            linebuf_flat <= {BUF_W{1'b0}};
        end else begin
            if (valid_in) begin
                wr_row = (pixel_count / IMG_WIDTH) % KERNEL_SIZE;
                wr_col = pixel_count % IMG_WIDTH;
                wr_bit = ((wr_row * IMG_WIDTH) + wr_col) * DATA_W;

                linebuf_flat[wr_bit +: DATA_W] <= pixel_in;
                pixel_count <= pixel_count + 32'd1;
            end
        end
    end

endmodule