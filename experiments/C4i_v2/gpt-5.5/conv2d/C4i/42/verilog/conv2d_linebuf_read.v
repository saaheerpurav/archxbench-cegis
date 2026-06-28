`timescale 1ns/1ps

module conv2d_linebuf_read #(
    parameter DATA_W      = 8,
    parameter IMG_WIDTH   = 64,
    parameter KERNEL_SIZE = 3
) (
    input  [KERNEL_SIZE*IMG_WIDTH*DATA_W-1:0]        linebuf_flat,
    input                                            valid_in,
    input  [31:0]                                    pixel_count,
    input  [DATA_W-1:0]                              current_pixel,
    input  [31:0]                                    in_row,
    input  [31:0]                                    in_col,
    input  [31:0]                                    out_row,
    input  [31:0]                                    out_col,
    output reg [KERNEL_SIZE*KERNEL_SIZE*DATA_W-1:0]  raw_window
);

    localparam integer RADIUS     = KERNEL_SIZE / 2;
    localparam integer WINDOW_BITS = KERNEL_SIZE * KERNEL_SIZE * DATA_W;

    integer kr;
    integer kc;
    integer bi;

    integer rr;
    integer cc;

    integer in_row_s;
    integer in_col_s;
    integer out_row_s;
    integer out_col_s;

    integer req_index;
    integer cur_index;
    integer avail_index;

    integer buf_row;
    integer bit_index;
    integer win_index;

    reg [DATA_W-1:0] pix;
    reg [DATA_W-1:0] read_pix;

    function has_unknown32;
        input [31:0] value;
        begin
            if ((^value) === 1'bx)
                has_unknown32 = 1'b1;
            else
                has_unknown32 = 1'b0;
        end
    endfunction

    function [DATA_W-1:0] clean_pixel;
        input [DATA_W-1:0] value;
        begin
            if ((^value) === 1'bx)
                clean_pixel = {DATA_W{1'b0}};
            else
                clean_pixel = value;
        end
    endfunction

    initial begin
        raw_window = {WINDOW_BITS{1'b0}};
    end

    always @* begin
        raw_window = {WINDOW_BITS{1'b0}};

        in_row_s  = $signed(in_row);
        in_col_s  = $signed(in_col);
        out_row_s = $signed(out_row);
        out_col_s = $signed(out_col);

        cur_index = (in_row_s * IMG_WIDTH) + in_col_s;

        if (valid_in === 1'b1) begin
            avail_index = cur_index;
        end else if (!has_unknown32(pixel_count)) begin
            avail_index = $signed(pixel_count) - 1;
        end else begin
            avail_index = -1;
        end

        for (kr = 0; kr < KERNEL_SIZE; kr = kr + 1) begin
            for (kc = 0; kc < KERNEL_SIZE; kc = kc + 1) begin
                rr = out_row_s + kr - RADIUS;
                cc = out_col_s + kc - RADIUS;

                win_index = ((kr * KERNEL_SIZE) + kc) * DATA_W;
                pix       = {DATA_W{1'b0}};

                if ((rr >= 0) && (cc >= 0) && (cc < IMG_WIDTH)) begin
                    req_index = (rr * IMG_WIDTH) + cc;

                    if ((valid_in === 1'b1) &&
                        (rr == in_row_s) &&
                        (cc == in_col_s)) begin
                        pix = clean_pixel(current_pixel);
                    end else if (req_index < avail_index) begin
                        buf_row   = rr % KERNEL_SIZE;
                        bit_index = ((buf_row * IMG_WIDTH) + cc) * DATA_W;
                        read_pix  = linebuf_flat[bit_index +: DATA_W];
                        pix       = clean_pixel(read_pix);
                    end else if ((valid_in !== 1'b1) && (req_index == avail_index)) begin
                        buf_row   = rr % KERNEL_SIZE;
                        bit_index = ((buf_row * IMG_WIDTH) + cc) * DATA_W;
                        read_pix  = linebuf_flat[bit_index +: DATA_W];
                        pix       = clean_pixel(read_pix);
                    end
                end

                raw_window[win_index +: DATA_W] = clean_pixel(pix);
            end
        end

        /*
         * Final hardening pass: guarantee this combinational block never
         * drives X/Z into the convolution datapath.  Known 1s are preserved;
         * known 0s, Xs, and Zs become 0.
         */
        for (bi = 0; bi < WINDOW_BITS; bi = bi + 1) begin
            if (raw_window[bi] !== 1'b1)
                raw_window[bi] = 1'b0;
        end
    end

endmodule