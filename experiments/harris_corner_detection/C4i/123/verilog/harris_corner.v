`timescale 1ns/1ps

module harris_corner #(
    parameter IMG_WIDTH = 128,
    parameter IMG_HEIGHT = 128,
    parameter PIXEL_W = 8,
    parameter GRAD_W = 16,
    parameter RESP_W = 32,
    parameter K_W = 8
) (
    input clk,
    input rst,
    input [PIXEL_W-1:0] pixel_in,
    input valid_in,
    input [RESP_W-1:0] threshold,
    input [K_W-1:0] k_param,
    output reg is_corner,
    output reg valid_out
);

    localparam PROD_W = 2*GRAD_W;
    localparam SMOOTH_W = PROD_W + 4;

    integer i;

    reg [31:0] row;
    reg [31:0] col;

    reg [PIXEL_W-1:0] pix_line0 [0:IMG_WIDTH-1];
    reg [PIXEL_W-1:0] pix_line1 [0:IMG_WIDTH-1];

    reg [PIXEL_W-1:0] w00, w01, w02;
    reg [PIXEL_W-1:0] w10, w11, w12;
    reg [PIXEL_W-1:0] w20, w21, w22;

    wire signed [GRAD_W-1:0] ix;
    wire signed [GRAD_W-1:0] iy;

    harris_sobel3x3 #(
        .PIXEL_W(PIXEL_W),
        .GRAD_W(GRAD_W)
    ) u_sobel (
        .p00(w00), .p01(w01), .p02(w02),
        .p10(w10), .p11(w11), .p12(w12),
        .p20(w20), .p21(w21), .p22(w22),
        .ix(ix),
        .iy(iy)
    );

    wire signed [PROD_W-1:0] ix2_now;
    wire signed [PROD_W-1:0] iy2_now;
    wire signed [PROD_W-1:0] ixy_now;

    harris_gradient_products #(
        .GRAD_W(GRAD_W),
        .PROD_W(PROD_W)
    ) u_products (
        .ix(ix),
        .iy(iy),
        .ix2(ix2_now),
        .iy2(iy2_now),
        .ixy(ixy_now)
    );

    reg signed [PROD_W-1:0] ix2_line0 [0:IMG_WIDTH-1];
    reg signed [PROD_W-1:0] ix2_line1 [0:IMG_WIDTH-1];
    reg signed [PROD_W-1:0] iy2_line0 [0:IMG_WIDTH-1];
    reg signed [PROD_W-1:0] iy2_line1 [0:IMG_WIDTH-1];
    reg signed [PROD_W-1:0] ixy_line0 [0:IMG_WIDTH-1];
    reg signed [PROD_W-1:0] ixy_line1 [0:IMG_WIDTH-1];

    reg signed [PROD_W-1:0] x00, x01, x02;
    reg signed [PROD_W-1:0] x10, x11, x12;
    reg signed [PROD_W-1:0] x20, x21, x22;

    reg signed [PROD_W-1:0] y00, y01, y02;
    reg signed [PROD_W-1:0] y10, y11, y12;
    reg signed [PROD_W-1:0] y20, y21, y22;

    reg signed [PROD_W-1:0] xy00, xy01, xy02;
    reg signed [PROD_W-1:0] xy10, xy11, xy12;
    reg signed [PROD_W-1:0] xy20, xy21, xy22;

    wire signed [SMOOTH_W-1:0] s_ix2;
    wire signed [SMOOTH_W-1:0] s_iy2;
    wire signed [SMOOTH_W-1:0] s_ixy;

    harris_gaussian3x3 #(
        .IN_W(PROD_W),
        .OUT_W(SMOOTH_W)
    ) u_gauss_ix2 (
        .p00(x00), .p01(x01), .p02(x02),
        .p10(x10), .p11(x11), .p12(x12),
        .p20(x20), .p21(x21), .p22(x22),
        .smooth(s_ix2)
    );

    harris_gaussian3x3 #(
        .IN_W(PROD_W),
        .OUT_W(SMOOTH_W)
    ) u_gauss_iy2 (
        .p00(y00), .p01(y01), .p02(y02),
        .p10(y10), .p11(y11), .p12(y12),
        .p20(y20), .p21(y21), .p22(y22),
        .smooth(s_iy2)
    );

    harris_gaussian3x3 #(
        .IN_W(PROD_W),
        .OUT_W(SMOOTH_W)
    ) u_gauss_ixy (
        .p00(xy00), .p01(xy01), .p02(xy02),
        .p10(xy10), .p11(xy11), .p12(xy12),
        .p20(xy20), .p21(xy21), .p22(xy22),
        .smooth(s_ixy)
    );

    wire signed [RESP_W-1:0] response;
    wire corner_comb;

    harris_response #(
        .IN_W(SMOOTH_W),
        .RESP_W(RESP_W),
        .K_W(K_W)
    ) u_response (
        .ix2(s_ix2),
        .iy2(s_iy2),
        .ixy(s_ixy),
        .k_param(k_param),
        .response(response)
    );

    harris_threshold #(
        .RESP_W(RESP_W)
    ) u_threshold (
        .response(response),
        .threshold(threshold),
        .is_corner(corner_comb)
    );

    always @(posedge clk) begin
        if (rst) begin
            row <= 0;
            col <= 0;
            valid_out <= 1'b0;
            is_corner <= 1'b0;

            w00 <= 0; w01 <= 0; w02 <= 0;
            w10 <= 0; w11 <= 0; w12 <= 0;
            w20 <= 0; w21 <= 0; w22 <= 0;

            x00 <= 0; x01 <= 0; x02 <= 0;
            x10 <= 0; x11 <= 0; x12 <= 0;
            x20 <= 0; x21 <= 0; x22 <= 0;

            y00 <= 0; y01 <= 0; y02 <= 0;
            y10 <= 0; y11 <= 0; y12 <= 0;
            y20 <= 0; y21 <= 0; y22 <= 0;

            xy00 <= 0; xy01 <= 0; xy02 <= 0;
            xy10 <= 0; xy11 <= 0; xy12 <= 0;
            xy20 <= 0; xy21 <= 0; xy22 <= 0;

            for (i = 0; i < IMG_WIDTH; i = i + 1) begin
                pix_line0[i] <= 0;
                pix_line1[i] <= 0;
                ix2_line0[i] <= 0;
                ix2_line1[i] <= 0;
                iy2_line0[i] <= 0;
                iy2_line1[i] <= 0;
                ixy_line0[i] <= 0;
                ixy_line1[i] <= 0;
            end
        end else begin
            valid_out <= valid_in;
            is_corner <= valid_in ? corner_comb : 1'b0;

            if (valid_in) begin
                pix_line1[col] <= pix_line0[col];
                pix_line0[col] <= pixel_in;

                ix2_line1[col] <= ix2_line0[col];
                ix2_line0[col] <= ix2_now;
                iy2_line1[col] <= iy2_line0[col];
                iy2_line0[col] <= iy2_now;
                ixy_line1[col] <= ixy_line0[col];
                ixy_line0[col] <= ixy_now;

                if (col == 0) begin
                    w00 <= 0; w01 <= 0; w02 <= pix_line1[col];
                    w10 <= 0; w11 <= 0; w12 <= pix_line0[col];
                    w20 <= 0; w21 <= 0; w22 <= pixel_in;

                    x00 <= 0; x01 <= 0; x02 <= ix2_line1[col];
                    x10 <= 0; x11 <= 0; x12 <= ix2_line0[col];
                    x20 <= 0; x21 <= 0; x22 <= ix2_now;

                    y00 <= 0; y01 <= 0; y02 <= iy2_line1[col];
                    y10 <= 0; y11 <= 0; y12 <= iy2_line0[col];
                    y20 <= 0; y21 <= 0; y22 <= iy2_now;

                    xy00 <= 0; xy01 <= 0; xy02 <= ixy_line1[col];
                    xy10 <= 0; xy11 <= 0; xy12 <= ixy_line0[col];
                    xy20 <= 0; xy21 <= 0; xy22 <= ixy_now;
                end else begin
                    w00 <= w01; w01 <= w02; w02 <= pix_line1[col];
                    w10 <= w11; w11 <= w12; w12 <= pix_line0[col];
                    w20 <= w21; w21 <= w22; w22 <= pixel_in;

                    x00 <= x01; x01 <= x02; x02 <= ix2_line1[col];
                    x10 <= x11; x11 <= x12; x12 <= ix2_line0[col];
                    x20 <= x21; x21 <= x22; x22 <= ix2_now;

                    y00 <= y01; y01 <= y02; y02 <= iy2_line1[col];
                    y10 <= y11; y11 <= y12; y12 <= iy2_line0[col];
                    y20 <= y21; y21 <= y22; y22 <= iy2_now;

                    xy00 <= xy01; xy01 <= xy02; xy02 <= ixy_line1[col];
                    xy10 <= xy11; xy11 <= xy12; xy12 <= ixy_line0[col];
                    xy20 <= xy21; xy21 <= xy22; xy22 <= ixy_now;
                end

                if (col == IMG_WIDTH-1) begin
                    col <= 0;
                    if (row == IMG_HEIGHT-1)
                        row <= 0;
                    else
                        row <= row + 1;
                end else begin
                    col <= col + 1;
                end
            end
        end
    end

endmodule