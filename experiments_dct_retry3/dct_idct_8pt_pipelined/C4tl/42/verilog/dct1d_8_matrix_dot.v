`timescale 1ns/1ps

module dct1d_8_matrix_dot #(
    parameter DATA_W = 12,
    parameter COEFF_W = 16,
    parameter OUT_W = 18
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

    wire signed [COEFF_W-1:0] c0, c1, c2, c3, c4, c5, c6, c7;
    wire signed [47:0] acc;
    wire signed [47:0] rounded;
    wire signed [47:0] shifted;

    dct1d_8_coeff_rom #(
        .COEFF_W(COEFF_W)
    ) u_coeff_rom (
        .mode(mode),
        .out_index(out_index),
        .c0(c0),
        .c1(c1),
        .c2(c2),
        .c3(c3),
        .c4(c4),
        .c5(c5),
        .c6(c6),
        .c7(c7)
    );

    assign acc =
        $signed(x0) * $signed(c0) +
        $signed(x1) * $signed(c1) +
        $signed(x2) * $signed(c2) +
        $signed(x3) * $signed(c3) +
        $signed(x4) * $signed(c4) +
        $signed(x5) * $signed(c5) +
        $signed(x6) * $signed(c6) +
        $signed(x7) * $signed(c7);

    assign rounded = (acc >= 0) ? (acc + 48'sd8192) : (acc - 48'sd8192);
    assign shifted = rounded >>> 14;

    dct1d_8_saturate #(
        .IN_W(48),
        .OUT_W(OUT_W)
    ) u_saturate (
        .din(shifted),
        .dout(y)
    );

endmodule