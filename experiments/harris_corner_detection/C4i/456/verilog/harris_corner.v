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
    output is_corner,
    output valid_out
);

    localparam PROD_W = (2*GRAD_W);
    localparam SMOOTH_W = (PROD_W+4);
    localparam RESP_INT_W = 64;

    integer i;

    reg [31:0] x_pos;
    reg [31:0] y_pos;

    reg [PIXEL_W-1:0] pix_line1 [0:IMG_WIDTH-1];
    reg [PIXEL_W-1:0] pix_line2 [0:IMG_WIDTH-1];

    reg [PIXEL_W-1:0] p00, p01, p02;
    reg [PIXEL_W-1:0] p10, p11, p12;
    reg [PIXEL_W-1:0] p20, p21, p22;

    wire signed [GRAD_W-1:0] ix_w;
    wire signed [GRAD_W-1:0] iy_w;

    harris_sobel3x3 #(
        .PIXEL_W(PIXEL_W),
        .GRAD_W(GRAD_W)
    ) u_sobel (
        .p00(p00), .p01(p01), .p02(p02),
        .p10(p10), .p11(p11), .p12(p12),
        .p20(p20), .p21(p21), .p22(p22),
        .ix(ix_w),
        .iy(iy_w)
    );

    wire [PROD_W-1:0] ix2_w;
    wire [PROD_W-1:0] iy2_w;
    wire signed [PROD_W-1:0] ixy_w;

    harris_gradient_products #(
        .GRAD_W(GRAD_W),
        .PROD_W(PROD_W)
    ) u_products (
        .ix(ix_w),
        .iy(iy_w),
        .ix2(ix2_w),
        .iy2(iy2_w),
        .ixy(ixy_w)
    );

    reg [PROD_W-1:0] ix2_line1 [0:IMG_WIDTH-1];
    reg [PROD_W-1:0] ix2_line2 [0:IMG_WIDTH-1];
    reg [PROD_W-1:0] iy2_line1 [0:IMG_WIDTH-1];
    reg [PROD_W-1:0] iy2_line2 [0:IMG_WIDTH-1];
    reg signed [PROD_W-1:0] ixy_line1 [0:IMG_WIDTH-1];
    reg signed [PROD_W-1:0] ixy_line2 [0:IMG_WIDTH-1];

    reg [PROD_W-1:0] ix2_00, ix2_01, ix2_02;
    reg [PROD_W-1:0] ix2_10, ix2_11, ix2_12;
    reg [PROD_W-1:0] ix2_20, ix2_21, ix2_22;

    reg [PROD_W-1:0] iy2_00, iy2_01, iy2_02;
    reg [PROD_W-1:0] iy2_10, iy2_11, iy2_12;
    reg [PROD_W-1:0] iy2_20, iy2_21, iy2_22;

    reg signed [PROD_W-1:0] ixy_00, ixy_01, ixy_02;
    reg signed [PROD_W-1:0] ixy_10, ixy_11, ixy_12;
    reg signed [PROD_W-1:0] ixy_20, ixy_21, ixy_22;

    wire signed [SMOOTH_W-1:0] s_ix2_w;
    wire signed [SMOOTH_W-1:0] s_iy2_w;
    wire signed [SMOOTH_W-1:0] s_ixy_w;

    harris_gaussian3x3 #(
        .IN_W(PROD_W),
        .OUT_W(SMOOTH_W)
    ) u_gauss_ix2 (
        .p00({1'b0, ix2_00[PROD_W-2:0]}), .p01({1'b0, ix2_01[PROD_W-2:0]}), .p02({1'b0, ix2_02[PROD_W-2:0]}),
        .p10({1'b0, ix2_10[PROD_W-2:0]}), .p11({1'b0, ix2_11[PROD_W-2:0]}), .p12({1'b0, ix2_12[PROD_W-2:0]}),
        .p20({1'b0, ix2_20[PROD_W-2:0]}), .p21({1'b0, ix2_21[PROD_W-2:0]}), .p22({1'b0, ix2_22[PROD_W-2:0]}),
        .smooth(s_ix2_w)
    );

    harris_gaussian3x3 #(
        .IN_W(PROD_W),
        .OUT_W(SMOOTH_W)
    ) u_gauss_iy2 (
        .p00({1'b0, iy2_00[PROD_W-2:0]}), .p01({1'b0, iy2_01[PROD_W-2:0]}), .p02({1'b0, iy2_02[PROD_W-2:0]}),
        .p10({1'b0, iy2_10[PROD_W-2:0]}), .p11({1'b0, iy2_11[PROD_W-2:0]}), .p12({1'b0, iy2_12[PROD_W-2:0]}),
        .p20({1'b0, iy2_20[PROD_W-2:0]}), .p21({1'b0, iy2_21[PROD_W-2:0]}), .p22({1'b0, iy2_22[PROD_W-2:0]}),
        .smooth(s_iy2_w)
    );

    harris_gaussian3x3 #(
        .IN_W(PROD_W),
        .OUT_W(SMOOTH_W)
    ) u_gauss_ixy (
        .p00(ixy_00), .p01(ixy_01), .p02(ixy_02),
        .p10(ixy_10), .p11(ixy_11), .p12(ixy_12),
        .p20(ixy_20), .p21(ixy_21), .p22(ixy_22),
        .smooth(s_ixy_w)
    );

    wire signed [RESP_W-1:0] response_w;

    harris_response_calc #(
        .SMOOTH_W(SMOOTH_W),
        .RESP_W(RESP_W),
        .K_W(K_W)
    ) u_response (
        .ix2_s(s_ix2_w),
        .iy2_s(s_iy2_w),
        .ixy_s(s_ixy_w),
        .k_param(k_param),
        .response(response_w)
    );

    wire corner_w;
    harris_threshold #(
        .RESP_W(RESP_W)
    ) u_threshold (
        .response(response_w),
        .threshold(threshold),
        .is_corner(corner_w)
    );

    reg is_corner_r;
    reg valid_out_r;

    assign is_corner = is_corner_r;
    assign valid_out = valid_out_r;

    always @(posedge clk) begin
        if (rst) begin
            x_pos <= 0;
            y_pos <= 0;
            p00 <= 0; p01 <= 0; p02 <= 0;
            p10 <= 0; p11 <= 0; p12 <= 0;
            p20 <= 0; p21 <= 0; p22 <= 0;

            ix2_00 <= 0; ix2_01 <= 0; ix2_02 <= 0;
            ix2_10 <= 0; ix2_11 <= 0; ix2_12 <= 0;
            ix2_20 <= 0; ix2_21 <= 0; ix2_22 <= 0;

            iy2_00 <= 0; iy2_01 <= 0; iy2_02 <= 0;
            iy2_10 <= 0; iy2_11 <= 0; iy2_12 <= 0;
            iy2_20 <= 0; iy2_21 <= 0; iy2_22 <= 0;

            ixy_00 <= 0; ixy_01 <= 0; ixy_02 <= 0;
            ixy_10 <= 0; ixy_11 <= 0; ixy_12 <= 0;
            ixy_20 <= 0; ixy_21 <= 0; ixy_22 <= 0;

            is_corner_r <= 0;
            valid_out_r <= 0;

            for (i = 0; i < IMG_WIDTH; i = i + 1) begin
                pix_line1[i] <= 0;
                pix_line2[i] <= 0;
                ix2_line1[i] <= 0;
                ix2_line2[i] <= 0;
                iy2_line1[i] <= 0;
                iy2_line2[i] <= 0;
                ixy_line1[i] <= 0;
                ixy_line2[i] <= 0;
            end
        end else begin
            valid_out_r <= valid_in;

            if (valid_in) begin
                if ((x_pos >= 4) && (y_pos >= 4))
                    is_corner_r <= corner_w;
                else
                    is_corner_r <= 1'b0;

                p00 <= p01; p01 <= p02; p02 <= pix_line2[x_pos];
                p10 <= p11; p11 <= p12; p12 <= pix_line1[x_pos];
                p20 <= p21; p21 <= p22; p22 <= pixel_in;

                pix_line2[x_pos] <= pix_line1[x_pos];
                pix_line1[x_pos] <= pixel_in;

                ix2_00 <= ix2_01; ix2_01 <= ix2_02; ix2_02 <= ix2_line2[x_pos];
                ix2_10 <= ix2_11; ix2_11 <= ix2_12; ix2_12 <= ix2_line1[x_pos];
                ix2_20 <= ix2_21; ix2_21 <= ix2_22; ix2_22 <= ix2_w;

                iy2_00 <= iy2_01; iy2_01 <= iy2_02; iy2_02 <= iy2_line2[x_pos];
                iy2_10 <= iy2_11; iy2_11 <= iy2_12; iy2_12 <= iy2_line1[x_pos];
                iy2_20 <= iy2_21; iy2_21 <= iy2_22; iy2_22 <= iy2_w;

                ixy_00 <= ixy_01; ixy_01 <= ixy_02; ixy_02 <= ixy_line2[x_pos];
                ixy_10 <= ixy_11; ixy_11 <= ixy_12; ixy_12 <= ixy_line1[x_pos];
                ixy_20 <= ixy_21; ixy_21 <= ixy_22; ixy_22 <= ixy_w;

                ix2_line2[x_pos] <= ix2_line1[x_pos];
                ix2_line1[x_pos] <= ix2_w;
                iy2_line2[x_pos] <= iy2_line1[x_pos];
                iy2_line1[x_pos] <= iy2_w;
                ixy_line2[x_pos] <= ixy_line1[x_pos];
                ixy_line1[x_pos] <= ixy_w;

                if (x_pos == IMG_WIDTH-1) begin
                    x_pos <= 0;
                    if (y_pos == IMG_HEIGHT-1)
                        y_pos <= 0;
                    else
                        y_pos <= y_pos + 1;
                end else begin
                    x_pos <= x_pos + 1;
                end
            end else begin
                is_corner_r <= 1'b0;
            end
        end
    end

endmodule