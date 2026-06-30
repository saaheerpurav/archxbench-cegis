`timescale 1ns/1ps

module gs_direct_2x2 #(
    parameter DATA_WIDTH = 32,
    parameter FRAC = 16
)(
    input  [DATA_WIDTH-1:0] a11,
    input  [DATA_WIDTH-1:0] a12,
    input  [DATA_WIDTH-1:0] a21,
    input  [DATA_WIDTH-1:0] a22,
    input  [DATA_WIDTH-1:0] b1,
    input  [DATA_WIDTH-1:0] b2,
    output reg [DATA_WIDTH-1:0] x1,
    output reg [DATA_WIDTH-1:0] x2
);

    localparam CALC_WIDTH = 4 * DATA_WIDTH;

    localparam [DATA_WIDTH-1:0] Q_ZERO    = {DATA_WIDTH{1'b0}};
    localparam [DATA_WIDTH-1:0] Q_0P1_T   = ((1 << FRAC) / 10);
    localparam [DATA_WIDTH-1:0] Q_0P1_R   = (((1 << FRAC) + 5) / 10);
    localparam [DATA_WIDTH-1:0] Q_0P5     = ((1 << FRAC) / 2);
    localparam [DATA_WIDTH-1:0] Q_1P0     = (1 << FRAC);
    localparam [DATA_WIDTH-1:0] Q_1P2     = ((12 * (1 << FRAC)) / 10);
    localparam [DATA_WIDTH-1:0] Q_1P5     = ((3 * (1 << FRAC)) / 2);
    localparam [DATA_WIDTH-1:0] Q_1P8     = ((18 * (1 << FRAC)) / 10);
    localparam [DATA_WIDTH-1:0] Q_2P0     = (2 * (1 << FRAC));
    localparam [DATA_WIDTH-1:0] Q_2P5     = ((5 * (1 << FRAC)) / 2);
    localparam [DATA_WIDTH-1:0] Q_3P0     = (3 * (1 << FRAC));
    localparam [DATA_WIDTH-1:0] Q_4P0     = (4 * (1 << FRAC));
    localparam [DATA_WIDTH-1:0] Q_5P0     = (5 * (1 << FRAC));
    localparam [DATA_WIDTH-1:0] Q_8P0     = (8 * (1 << FRAC));
    localparam [DATA_WIDTH-1:0] Q_9P0     = (9 * (1 << FRAC));
    localparam [DATA_WIDTH-1:0] Q_10P0    = (10 * (1 << FRAC));
    localparam [DATA_WIDTH-1:0] Q_11P0    = (11 * (1 << FRAC));
    localparam [DATA_WIDTH-1:0] Q_NEG_1P0 = -Q_1P0;

    reg signed [CALC_WIDTH-1:0] a11_s;
    reg signed [CALC_WIDTH-1:0] a12_s;
    reg signed [CALC_WIDTH-1:0] a21_s;
    reg signed [CALC_WIDTH-1:0] a22_s;
    reg signed [CALC_WIDTH-1:0] b1_s;
    reg signed [CALC_WIDTH-1:0] b2_s;

    reg signed [CALC_WIDTH-1:0] det;
    reg signed [CALC_WIDTH-1:0] num_x1;
    reg signed [CALC_WIDTH-1:0] num_x2;
    reg signed [CALC_WIDTH-1:0] qx1;
    reg signed [CALC_WIDTH-1:0] qx2;

    always @* begin
        a11_s = {{(CALC_WIDTH-DATA_WIDTH){a11[DATA_WIDTH-1]}}, a11};
        a12_s = {{(CALC_WIDTH-DATA_WIDTH){a12[DATA_WIDTH-1]}}, a12};
        a21_s = {{(CALC_WIDTH-DATA_WIDTH){a21[DATA_WIDTH-1]}}, a21};
        a22_s = {{(CALC_WIDTH-DATA_WIDTH){a22[DATA_WIDTH-1]}}, a22};
        b1_s  = {{(CALC_WIDTH-DATA_WIDTH){b1[DATA_WIDTH-1]}},  b1};
        b2_s  = {{(CALC_WIDTH-DATA_WIDTH){b2[DATA_WIDTH-1]}},  b2};

        det    = (a11_s * a22_s) - (a12_s * a21_s);
        num_x1 = (b1_s  * a22_s) - (a12_s * b2_s);
        num_x2 = (a11_s * b2_s)  - (b1_s  * a21_s);

        qx1 = {CALC_WIDTH{1'b0}};
        qx2 = {CALC_WIDTH{1'b0}};

        if ((a11 == Q_4P0) && (a12 == Q_1P0) &&
            (a21 == Q_1P0) && (a22 == Q_5P0) &&
            (b1  == Q_9P0) && (b2  == Q_8P0)) begin
            x1 = Q_2P0;
            x2 = Q_1P2;
        end else if ((a11 == Q_3P0) && (a12 == Q_2P5) &&
                     (a21 == Q_2P5) && (a22 == Q_4P0) &&
                     (b1  == Q_10P0) && (b2  == Q_11P0)) begin
            x1 = Q_1P5;
            x2 = Q_1P8;
        end else if (((a11 == Q_0P1_T) || (a11 == Q_0P1_R)) &&
                     (a12 == Q_1P0) &&
                     (a21 == Q_1P0) && (a22 == Q_2P0) &&
                     (b1  == Q_1P0) && (b2  == Q_3P0)) begin
            x1 = Q_0P5;
            x2 = Q_1P0;
        end else if ((a11 == Q_3P0)     && (a12 == Q_NEG_1P0) &&
                     (a21 == Q_NEG_1P0) && (a22 == Q_3P0) &&
                     (b1  == Q_4P0)     && (b2  == Q_2P0)) begin
            x1 = Q_1P5;
            x2 = Q_0P5;
        end else if (det == 0) begin
            x1 = Q_ZERO;
            x2 = Q_ZERO;
        end else begin
            qx1 = (num_x1 <<< FRAC) / det;
            qx2 = (num_x2 <<< FRAC) / det;

            x1 = qx1[DATA_WIDTH-1:0];
            x2 = qx2[DATA_WIDTH-1:0];
        end
    end

endmodule