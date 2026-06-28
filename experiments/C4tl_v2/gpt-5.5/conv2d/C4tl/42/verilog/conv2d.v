`timescale 1ns/1ps

module conv2d #(
    parameter DATA_W      = 8,
    parameter IMG_WIDTH   = 64,
    parameter KERNEL_SIZE = 3,
    parameter GAIN_W      = 4
) (
    input                           clk,
    input                           rst,
    input                           valid_in,
    input      [DATA_W-1:0]         pixel_in,
    output reg                      valid_out,
    output reg [DATA_W+GAIN_W-1:0]  pixel_out
);

    function integer CLOG2;
        input integer value;
        integer v;
        begin
            v = value - 1;
            CLOG2 = 0;
            while (v > 0) begin
                v = v >> 1;
                CLOG2 = CLOG2 + 1;
            end
        end
    endfunction

    localparam NUM_LINE_BUFFERS = KERNEL_SIZE - 1;
    localparam LINE_DEPTH       = NUM_LINE_BUFFERS * IMG_WIDTH;
    localparam HSHIFT_DEPTH     = KERNEL_SIZE * (KERNEL_SIZE - 1);
    localparam WINDOW_ELEMS     = KERNEL_SIZE * KERNEL_SIZE;
    localparam WINDOW_W         = WINDOW_ELEMS * DATA_W;
    localparam COEFF_W          = 16;
    localparam COEFFS_W         = WINDOW_ELEMS * COEFF_W;
    localparam ACC_W            = DATA_W + COEFF_W + CLOG2(WINDOW_ELEMS) + 2;
    localparam OUT_W            = DATA_W + GAIN_W;
    localparam COORD_W          = 32;

    reg [DATA_W-1:0] line_mem [0:LINE_DEPTH-1];
    reg [DATA_W-1:0] hshift   [0:HSHIFT_DEPTH-1];

    reg [COORD_W-1:0] col_cnt;
    reg [COORD_W-1:0] row_cnt;

    wire [DATA_W-1:0] row_tap [0:KERNEL_SIZE-1];
    wire [WINDOW_W-1:0] raw_window;
    wire [WINDOW_W-1:0] padded_window;
    wire [COEFFS_W-1:0] coeffs_flat;
    wire signed [ACC_W-1:0] acc_value;
    wire [OUT_W-1:0] saturated_value;
    wire valid_center;

    genvar gr;
    genvar gc;

    generate
        for (gr = 0; gr < KERNEL_SIZE; gr = gr + 1) begin : GEN_ROW_TAPS
            if (gr == 0) begin : GEN_CURRENT_ROW
                assign row_tap[gr] = pixel_in;
            end else begin : GEN_DELAYED_ROW
                assign row_tap[gr] = line_mem[(gr * IMG_WIDTH) - 1];
            end
        end
    endgenerate

    generate
        for (gr = 0; gr < KERNEL_SIZE; gr = gr + 1) begin : GEN_WINDOW_ROWS
            for (gc = 0; gc < KERNEL_SIZE; gc = gc + 1) begin : GEN_WINDOW_COLS
                if (gc == 0) begin : GEN_CURRENT_COL
                    assign raw_window[((gr*KERNEL_SIZE + gc)*DATA_W) +: DATA_W] = row_tap[gr];
                end else begin : GEN_DELAYED_COL
                    assign raw_window[((gr*KERNEL_SIZE + gc)*DATA_W) +: DATA_W] =
                        hshift[(gr*(KERNEL_SIZE-1)) + (gc-1)];
                end
            end
        end
    endgenerate

    conv2d_valid_gen #(
        .KERNEL_SIZE(KERNEL_SIZE),
        .COORD_W(COORD_W)
    ) u_valid_gen (
        .valid_in(valid_in),
        .row_cnt(row_cnt),
        .col_cnt(col_cnt),
        .valid_out(valid_center)
    );

    conv2d_window_pad #(
        .DATA_W(DATA_W),
        .KERNEL_SIZE(KERNEL_SIZE),
        .COORD_W(COORD_W)
    ) u_window_pad (
        .row_cnt(row_cnt),
        .col_cnt(col_cnt),
        .raw_window(raw_window),
        .padded_window(padded_window)
    );

    conv2d_coeff_rom #(
        .KERNEL_SIZE(KERNEL_SIZE),
        .COEFF_W(COEFF_W)
    ) u_coeff_rom (
        .coeffs_flat(coeffs_flat)
    );

    conv2d_dot_product #(
        .DATA_W(DATA_W),
        .KERNEL_SIZE(KERNEL_SIZE),
        .COEFF_W(COEFF_W),
        .ACC_W(ACC_W)
    ) u_dot_product (
        .window_flat(padded_window),
        .coeffs_flat(coeffs_flat),
        .acc_out(acc_value)
    );

    conv2d_output_saturate #(
        .ACC_W(ACC_W),
        .OUT_W(OUT_W)
    ) u_output_saturate (
        .acc_in(acc_value),
        .pixel_out(saturated_value)
    );

    integer i;
    integer r;
    integer c;

    always @(posedge clk) begin
        if (rst) begin
            valid_out <= 1'b0;
            pixel_out <= {OUT_W{1'b0}};
            col_cnt <= {COORD_W{1'b0}};
            row_cnt <= {COORD_W{1'b0}};

            for (i = 0; i < LINE_DEPTH; i = i + 1) begin
                line_mem[i] <= {DATA_W{1'b0}};
            end

            for (i = 0; i < HSHIFT_DEPTH; i = i + 1) begin
                hshift[i] <= {DATA_W{1'b0}};
            end
        end else begin
            if (valid_in) begin
                valid_out <= valid_center;
                pixel_out <= saturated_value;

                line_mem[0] <= pixel_in;
                for (i = 1; i < LINE_DEPTH; i = i + 1) begin
                    line_mem[i] <= line_mem[i-1];
                end

                for (r = 0; r < KERNEL_SIZE; r = r + 1) begin
                    hshift[r*(KERNEL_SIZE-1)] <= row_tap[r];
                    for (c = 1; c < (KERNEL_SIZE-1); c = c + 1) begin
                        hshift[(r*(KERNEL_SIZE-1)) + c] <=
                            hshift[(r*(KERNEL_SIZE-1)) + c - 1];
                    end
                end

                if (col_cnt == IMG_WIDTH - 1) begin
                    col_cnt <= {COORD_W{1'b0}};
                    row_cnt <= row_cnt + {{(COORD_W-1){1'b0}}, 1'b1};
                end else begin
                    col_cnt <= col_cnt + {{(COORD_W-1){1'b0}}, 1'b1};
                end
            end else begin
                valid_out <= 1'b0;
                pixel_out <= {OUT_W{1'b0}};
            end
        end
    end

endmodule