`timescale 1ns/1ps

module dct1d_8_pipeline #(
    parameter DATA_W = 12,
    parameter COEFF_W = 16,
    parameter OUT_W = 18
) (
    input clk,
    input rst,
    input [DATA_W-1:0] sample_in,
    input valid_in,
    input mode, // 0 = DCT, 1 = IDCT
    input [2:0] index,
    output [OUT_W-1:0] coeff_out,
    output valid_out,
    output [2:0] index_out
);

    localparam ACC_W = DATA_W + COEFF_W + 4;
    localparam FRAC_BITS = 14;

    reg signed [DATA_W-1:0] sample_buf [0:7];
    reg frame_mode;
    reg active;
    reg [2:0] out_idx;

    reg [OUT_W-1:0] coeff_out_r;
    reg valid_out_r;
    reg [2:0] index_out_r;

    wire signed [DATA_W-1:0] sample_s;
    assign sample_s = sample_in;

    wire [2:0] calc_idx;
    assign calc_idx = out_idx;

    wire signed [COEFF_W-1:0] c0;
    wire signed [COEFF_W-1:0] c1;
    wire signed [COEFF_W-1:0] c2;
    wire signed [COEFF_W-1:0] c3;
    wire signed [COEFF_W-1:0] c4;
    wire signed [COEFF_W-1:0] c5;
    wire signed [COEFF_W-1:0] c6;
    wire signed [COEFF_W-1:0] c7;

    dct1d_8_coeff_rom #(.COEFF_W(COEFF_W)) u_c0 (.mode(frame_mode), .out_index(calc_idx), .sample_index(3'd0), .coeff(c0));
    dct1d_8_coeff_rom #(.COEFF_W(COEFF_W)) u_c1 (.mode(frame_mode), .out_index(calc_idx), .sample_index(3'd1), .coeff(c1));
    dct1d_8_coeff_rom #(.COEFF_W(COEFF_W)) u_c2 (.mode(frame_mode), .out_index(calc_idx), .sample_index(3'd2), .coeff(c2));
    dct1d_8_coeff_rom #(.COEFF_W(COEFF_W)) u_c3 (.mode(frame_mode), .out_index(calc_idx), .sample_index(3'd3), .coeff(c3));
    dct1d_8_coeff_rom #(.COEFF_W(COEFF_W)) u_c4 (.mode(frame_mode), .out_index(calc_idx), .sample_index(3'd4), .coeff(c4));
    dct1d_8_coeff_rom #(.COEFF_W(COEFF_W)) u_c5 (.mode(frame_mode), .out_index(calc_idx), .sample_index(3'd5), .coeff(c5));
    dct1d_8_coeff_rom #(.COEFF_W(COEFF_W)) u_c6 (.mode(frame_mode), .out_index(calc_idx), .sample_index(3'd6), .coeff(c6));
    dct1d_8_coeff_rom #(.COEFF_W(COEFF_W)) u_c7 (.mode(frame_mode), .out_index(calc_idx), .sample_index(3'd7), .coeff(c7));

    wire signed [ACC_W-1:0] mac_sum;
    wire signed [ACC_W-1:0] rounded_sum;
    wire signed [ACC_W-1:0] scaled_sum;
    wire [OUT_W-1:0] clipped_sum;

    dct1d_8_mac #(
        .DATA_W(DATA_W),
        .COEFF_W(COEFF_W),
        .ACC_W(ACC_W)
    ) u_mac (
        .x0(sample_buf[0]), .x1(sample_buf[1]), .x2(sample_buf[2]), .x3(sample_buf[3]),
        .x4(sample_buf[4]), .x5(sample_buf[5]), .x6(sample_buf[6]), .x7(sample_buf[7]),
        .c0(c0), .c1(c1), .c2(c2), .c3(c3),
        .c4(c4), .c5(c5), .c6(c6), .c7(c7),
        .sum(mac_sum)
    );

    dct1d_8_round_shift #(
        .IN_W(ACC_W),
        .SHIFT(FRAC_BITS)
    ) u_round_shift (
        .in_value(mac_sum),
        .out_value(scaled_sum)
    );

    dct1d_8_saturate #(
        .IN_W(ACC_W),
        .OUT_W(OUT_W)
    ) u_saturate (
        .in_value(scaled_sum),
        .out_value(clipped_sum)
    );

    assign rounded_sum = scaled_sum;
    assign coeff_out = coeff_out_r;
    assign valid_out = valid_out_r;
    assign index_out = index_out_r;

    integer i;
    always @(posedge clk) begin
        if (rst) begin
            for (i = 0; i < 8; i = i + 1) begin
                sample_buf[i] <= {DATA_W{1'b0}};
            end
            frame_mode <= 1'b0;
            active <= 1'b0;
            out_idx <= 3'd0;
            coeff_out_r <= {OUT_W{1'b0}};
            valid_out_r <= 1'b0;
            index_out_r <= 3'd0;
        end else begin
            valid_out_r <= 1'b0;

            if (valid_in) begin
                sample_buf[index] <= sample_s;
                if (index == 3'd0) begin
                    frame_mode <= mode;
                end
                if (index == 3'd7) begin
                    active <= 1'b1;
                    out_idx <= 3'd0;
                end
            end

            if (active) begin
                coeff_out_r <= clipped_sum;
                valid_out_r <= 1'b1;
                index_out_r <= out_idx;
                if (out_idx == 3'd7) begin
                    active <= 1'b0;
                    out_idx <= 3'd0;
                end else begin
                    out_idx <= out_idx + 3'd1;
                end
            end
        end
    end

endmodule