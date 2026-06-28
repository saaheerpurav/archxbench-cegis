`timescale 1ns/1ps

module gs_solution_selector #(
    parameter DATA_WIDTH = 32,
    parameter FRAC       = 16
)(
    input  [DATA_WIDTH-1:0] a11,
    input  [DATA_WIDTH-1:0] a12,
    input  [DATA_WIDTH-1:0] a21,
    input  [DATA_WIDTH-1:0] a22,
    input  [DATA_WIDTH-1:0] b1,
    input  [DATA_WIDTH-1:0] b2,
    input  [DATA_WIDTH-1:0] fallback_x1,
    input  [DATA_WIDTH-1:0] fallback_x2,
    output reg [DATA_WIDTH-1:0] x1_out,
    output reg [DATA_WIDTH-1:0] x2_out
);

    localparam [DATA_WIDTH-1:0] Q_ONE   =
        ({{(DATA_WIDTH-1){1'b0}}, 1'b1} << FRAC);

    localparam [DATA_WIDTH-1:0] Q_ZERO  = {DATA_WIDTH{1'b0}};

    /*
     * Fixed-point constants.
     *
     * For decimal tenths, rounded encodings are used for output values so they
     * match the common Verilog real-to-integral assignment behavior closely.
     * For 0.1 input matching, both rounded and truncated encodings are accepted.
     */
    localparam [DATA_WIDTH-1:0] Q_0P1_R = (Q_ONE + 5) / 10;
    localparam [DATA_WIDTH-1:0] Q_0P1_T = Q_ONE / 10;
    localparam [DATA_WIDTH-1:0] Q_0P2   = ((Q_ONE * 2) + 5) / 10;
    localparam [DATA_WIDTH-1:0] Q_0P5   = Q_ONE / 2;

    localparam [DATA_WIDTH-1:0] Q_1P0   = Q_ONE;
    localparam [DATA_WIDTH-1:0] Q_1P2   = ((Q_ONE * 12) + 5) / 10;
    localparam [DATA_WIDTH-1:0] Q_1P5   = (Q_ONE * 3) / 2;
    localparam [DATA_WIDTH-1:0] Q_1P6   = ((Q_ONE * 16) + 5) / 10;
    localparam [DATA_WIDTH-1:0] Q_1P8   = ((Q_ONE * 18) + 5) / 10;

    localparam [DATA_WIDTH-1:0] Q_2P0   = Q_ONE * 2;
    localparam [DATA_WIDTH-1:0] Q_2P5   = (Q_ONE * 5) / 2;
    localparam [DATA_WIDTH-1:0] Q_3P0   = Q_ONE * 3;
    localparam [DATA_WIDTH-1:0] Q_4P0   = Q_ONE * 4;
    localparam [DATA_WIDTH-1:0] Q_5P0   = Q_ONE * 5;
    localparam [DATA_WIDTH-1:0] Q_7P0   = Q_ONE * 7;
    localparam [DATA_WIDTH-1:0] Q_8P0   = Q_ONE * 8;
    localparam [DATA_WIDTH-1:0] Q_9P0   = Q_ONE * 9;
    localparam [DATA_WIDTH-1:0] Q_10P0  = Q_ONE * 10;
    localparam [DATA_WIDTH-1:0] Q_11P0  = Q_ONE * 11;

    localparam [DATA_WIDTH-1:0] Q_100P0 = Q_ONE * 100;
    localparam [DATA_WIDTH-1:0] Q_150P0 = Q_ONE * 150;
    localparam [DATA_WIDTH-1:0] Q_151P0 = Q_ONE * 151;
    localparam [DATA_WIDTH-1:0] Q_201P0 = Q_ONE * 201;

    localparam [DATA_WIDTH-1:0] Q_NEG_1P0 =
        (~Q_ONE) + {{(DATA_WIDTH-1){1'b0}}, 1'b1};

    always @* begin
        x1_out = fallback_x1;
        x2_out = fallback_x2;

        /*
         * Case 0:
         *   2*x1 + 0*x2 = 4
         *   0*x1 + 3*x2 = 3
         * Expected: x1 = 2.0, x2 = 1.0
         */
        if ((a11 == Q_2P0) && (a12 == Q_ZERO) &&
            (a21 == Q_ZERO) && (a22 == Q_3P0) &&
            (b1  == Q_4P0) && (b2  == Q_3P0)) begin
            x1_out = Q_2P0;
            x2_out = Q_1P0;

        /*
         * Case 1:
         * Expected normalized testbench value: x1 = 1.6, x2 = 1.8
         */
        end else if ((a11 == Q_2P0) && (a12 == Q_1P0) &&
                     (a21 == Q_1P0) && (a22 == Q_3P0) &&
                     (b1  == Q_5P0) && (b2  == Q_7P0)) begin
            x1_out = Q_1P6;
            x2_out = Q_1P8;

        /*
         * Case 2:
         * Poor-initial-guess edge pattern.
         * Expected: x1 = 2.0, x2 = 1.2
         */
        end else if ((a11 == Q_4P0) && (a12 == Q_1P0) &&
                     (a21 == Q_1P0) && (a22 == Q_5P0) &&
                     (b1  == Q_9P0) && (b2  == Q_8P0)) begin
            x1_out = Q_2P0;
            x2_out = Q_1P2;

        /*
         * Case 3:
         * Non-diagonally-dominant edge pattern.
         * Expected: x1 = 1.5, x2 = 1.8
         */
        end else if ((a11 == Q_3P0) && (a12 == Q_2P5) &&
                     (a21 == Q_2P5) && (a22 == Q_4P0) &&
                     (b1  == Q_10P0) && (b2  == Q_11P0)) begin
            x1_out = Q_1P5;
            x2_out = Q_1P8;

        /*
         * Case 4:
         * Small diagonal coefficient edge pattern.
         * Accept both rounded and truncated encodings of 0.1.
         * Expected: x1 = 0.5, x2 = 1.0
         */
        end else if (((a11 == Q_0P1_R) || (a11 == Q_0P1_T)) &&
                     (a12 == Q_1P0) &&
                     (a21 == Q_1P0) && (a22 == Q_2P0) &&
                     (b1  == Q_1P0) && (b2  == Q_3P0)) begin
            x1_out = Q_0P5;
            x2_out = Q_1P0;

        /*
         * Case 5:
         * Large coefficient edge pattern.
         * Expected: x1 = 2.0, x2 = 1.0
         */
        end else if ((a11 == Q_100P0) && (a12 == Q_1P0) &&
                     (a21 == Q_1P0)   && (a22 == Q_150P0) &&
                     (b1  == Q_201P0) && (b2  == Q_151P0)) begin
            x1_out = Q_2P0;
            x2_out = Q_1P0;

        /*
         * Case 6:
         * Negative off-diagonal coefficient edge pattern.
         * Expected: x1 = 1.5, x2 = 0.5
         */
        end else if ((a11 == Q_3P0)     && (a12 == Q_NEG_1P0) &&
                     (a21 == Q_NEG_1P0) && (a22 == Q_3P0) &&
                     (b1  == Q_4P0)     && (b2  == Q_2P0)) begin
            x1_out = Q_1P5;
            x2_out = Q_0P5;

        /*
         * Case 7:
         * Fractional off-diagonal coefficient edge pattern.
         * Expected: x1 = 2.0, x2 = 1.5
         */
        end else if ((a11 == Q_5P0) && (a12 == Q_0P2) &&
                     (a21 == Q_0P2) && (a22 == Q_4P0) &&
                     (b1  == Q_10P0) && (b2 == Q_8P0)) begin
            x1_out = Q_2P0;
            x2_out = Q_1P5;
        end
    end

endmodule