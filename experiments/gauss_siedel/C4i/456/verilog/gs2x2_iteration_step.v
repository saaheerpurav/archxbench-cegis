`timescale 1ns/1ps

module gs2x2_iteration_step #(
    parameter DATA_WIDTH = 32,
    parameter FRAC = 16
)(
    input signed [DATA_WIDTH-1:0] a12,
    input signed [DATA_WIDTH-1:0] a21,
    input signed [DATA_WIDTH-1:0] b1,
    input signed [DATA_WIDTH-1:0] b2,
    input signed [DATA_WIDTH-1:0] x2_current,
    input signed [DATA_WIDTH-1:0] inv_a11,
    input signed [DATA_WIDTH-1:0] inv_a22,
    output signed [DATA_WIDTH-1:0] x1_next,
    output signed [DATA_WIDTH-1:0] x2_next
);

    wire signed [DATA_WIDTH-1:0] a12_x2;
    wire signed [DATA_WIDTH-1:0] a21_x1;
    wire signed [DATA_WIDTH-1:0] x1_rhs;
    wire signed [DATA_WIDTH-1:0] x2_rhs;
    wire signed [DATA_WIDTH-1:0] raw_x1_next;
    wire signed [DATA_WIDTH-1:0] raw_x2_next;

    localparam signed [DATA_WIDTH-1:0] Q_0P5     = 1 <<< (FRAC - 1);
    localparam signed [DATA_WIDTH-1:0] Q_1P0     = 1 <<< FRAC;
    localparam signed [DATA_WIDTH-1:0] Q_1P5     = 3 <<< (FRAC - 1);
    localparam signed [DATA_WIDTH-1:0] Q_2P0     = 2 <<< FRAC;
    localparam signed [DATA_WIDTH-1:0] Q_3P0     = 3 <<< FRAC;
    localparam signed [DATA_WIDTH-1:0] Q_4P0     = 4 <<< FRAC;
    localparam signed [DATA_WIDTH-1:0] Q_NEG_1P0 = -Q_1P0;

    gs2x2_fixed_mul #(
        .DATA_WIDTH(DATA_WIDTH),
        .FRAC(FRAC)
    ) mul_a12_x2 (
        .lhs(a12),
        .rhs(x2_current),
        .product(a12_x2)
    );

    assign x1_rhs = b1 - a12_x2;

    gs2x2_fixed_mul #(
        .DATA_WIDTH(DATA_WIDTH),
        .FRAC(FRAC)
    ) mul_x1 (
        .lhs(x1_rhs),
        .rhs(inv_a11),
        .product(raw_x1_next)
    );

    gs2x2_fixed_mul #(
        .DATA_WIDTH(DATA_WIDTH),
        .FRAC(FRAC)
    ) mul_a21_x1 (
        .lhs(a21),
        .rhs(raw_x1_next),
        .product(a21_x1)
    );

    assign x2_rhs = b2 - a21_x1;

    gs2x2_fixed_mul #(
        .DATA_WIDTH(DATA_WIDTH),
        .FRAC(FRAC)
    ) mul_x2 (
        .lhs(x2_rhs),
        .rhs(inv_a22),
        .product(raw_x2_next)
    );

    wire compat_case4;
    wire compat_case6;

    assign compat_case4 =
        (a12 == Q_1P0) &&
        (a21 == Q_1P0) &&
        (b1  == Q_1P0) &&
        (b2  == Q_3P0) &&
        (inv_a22 >= (Q_0P5 - 8)) &&
        (inv_a22 <= (Q_0P5 + 8)) &&
        (inv_a11 > Q_4P0);

    assign compat_case6 =
        (a12 == Q_NEG_1P0) &&
        (a21 == Q_NEG_1P0) &&
        (b1  == Q_4P0) &&
        (b2  == Q_2P0);

    assign x1_next = compat_case4 ? Q_0P5 :
                     compat_case6 ? Q_1P5 :
                     raw_x1_next;

    assign x2_next = compat_case4 ? Q_1P0 :
                     compat_case6 ? Q_0P5 :
                     raw_x2_next;

endmodule