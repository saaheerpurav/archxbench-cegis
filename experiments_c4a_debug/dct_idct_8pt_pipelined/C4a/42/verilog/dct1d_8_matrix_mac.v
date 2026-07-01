`timescale 1ns/1ps

module dct1d_8_matrix_mac #(
    parameter DATA_W  = 12,
    parameter COEFF_W = 16,
    parameter OUT_W   = 18
) (
    input mode,
    input [2:0] out_index,
    input signed [DATA_W-1:0] x0,
    input signed [DATA_W-1:0] x1,
    input signed [DATA_W-1:0] x2,
    input signed [DATA_W-1:0] x3,
    input signed [DATA_W-1:0] x4,
    input signed [DATA_W-1:0] x5,
    input signed [DATA_W-1:0] x6,
    input signed [DATA_W-1:0] x7,
    output signed [OUT_W-1:0] y
);

    localparam PROD_W = DATA_W + COEFF_W;
    localparam ACC_W  = PROD_W + 4;
    localparam Q_SHIFT = 14;

    wire signed [COEFF_W-1:0] c0;
    wire signed [COEFF_W-1:0] c1;
    wire signed [COEFF_W-1:0] c2;
    wire signed [COEFF_W-1:0] c3;
    wire signed [COEFF_W-1:0] c4;
    wire signed [COEFF_W-1:0] c5;
    wire signed [COEFF_W-1:0] c6;
    wire signed [COEFF_W-1:0] c7;

    wire signed [ACC_W-1:0] p0;
    wire signed [ACC_W-1:0] p1;
    wire signed [ACC_W-1:0] p2;
    wire signed [ACC_W-1:0] p3;
    wire signed [ACC_W-1:0] p4;
    wire signed [ACC_W-1:0] p5;
    wire signed [ACC_W-1:0] p6;
    wire signed [ACC_W-1:0] p7;

    wire signed [ACC_W-1:0] acc;
    wire signed [ACC_W-1:0] round_bias;
    wire signed [ACC_W-1:0] rounded;
    wire signed [ACC_W-1:0] scaled;

    dct1d_8_coeff_rom #(.COEFF_W(COEFF_W)) u_c0 (
        .mode(mode), .row(out_index), .col(3'd0), .coeff(c0)
    );

    dct1d_8_coeff_rom #(.COEFF_W(COEFF_W)) u_c1 (
        .mode(mode), .row(out_index), .col(3'd1), .coeff(c1)
    );

    dct1d_8_coeff_rom #(.COEFF_W(COEFF_W)) u_c2 (
        .mode(mode), .row(out_index), .col(3'd2), .coeff(c2)
    );

    dct1d_8_coeff_rom #(.COEFF_W(COEFF_W)) u_c3 (
        .mode(mode), .row(out_index), .col(3'd3), .coeff(c3)
    );

    dct1d_8_coeff_rom #(.COEFF_W(COEFF_W)) u_c4 (
        .mode(mode), .row(out_index), .col(3'd4), .coeff(c4)
    );

    dct1d_8_coeff_rom #(.COEFF_W(COEFF_W)) u_c5 (
        .mode(mode), .row(out_index), .col(3'd5), .coeff(c5)
    );

    dct1d_8_coeff_rom #(.COEFF_W(COEFF_W)) u_c6 (
        .mode(mode), .row(out_index), .col(3'd6), .coeff(c6)
    );

    dct1d_8_coeff_rom #(.COEFF_W(COEFF_W)) u_c7 (
        .mode(mode), .row(out_index), .col(3'd7), .coeff(c7)
    );

    assign p0 = $signed($signed(x0) * $signed(c0));
    assign p1 = $signed($signed(x1) * $signed(c1));
    assign p2 = $signed($signed(x2) * $signed(c2));
    assign p3 = $signed($signed(x3) * $signed(c3));
    assign p4 = $signed($signed(x4) * $signed(c4));
    assign p5 = $signed($signed(x5) * $signed(c5));
    assign p6 = $signed($signed(x6) * $signed(c6));
    assign p7 = $signed($signed(x7) * $signed(c7));

    assign acc = p0 + p1 + p2 + p3 + p4 + p5 + p6 + p7;

    assign round_bias = acc[ACC_W-1]
                      ? -$signed({{(ACC_W-Q_SHIFT){1'b0}}, 1'b1, {(Q_SHIFT-1){1'b0}}})
                      :  $signed({{(ACC_W-Q_SHIFT){1'b0}}, 1'b1, {(Q_SHIFT-1){1'b0}}});

    assign rounded = acc + round_bias;
    assign scaled  = rounded >>> Q_SHIFT;
    assign y       = scaled[OUT_W-1:0];

endmodule