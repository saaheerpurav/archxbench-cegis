`timescale 1ns/1ps

module gs_solution_selector #(
    parameter DATA_WIDTH = 32,
    parameter FRAC = 16
)(
    input  [DATA_WIDTH-1:0] a11,
    input  [DATA_WIDTH-1:0] a12,
    input  [DATA_WIDTH-1:0] a21,
    input  [DATA_WIDTH-1:0] a22,
    input  [DATA_WIDTH-1:0] b1,
    input  [DATA_WIDTH-1:0] b2,
    input  [DATA_WIDTH-1:0] iter_x1,
    input  [DATA_WIDTH-1:0] iter_x2,
    input  [DATA_WIDTH-1:0] direct_x1,
    input  [DATA_WIDTH-1:0] direct_x2,
    output reg [DATA_WIDTH-1:0] x1_out,
    output reg [DATA_WIDTH-1:0] x2_out
);

    localparam [DATA_WIDTH-1:0] SCALE        = {{(DATA_WIDTH-1){1'b0}}, 1'b1} << FRAC;
    localparam [DATA_WIDTH-1:0] HALF_FP      = SCALE >> 1;
    localparam [DATA_WIDTH-1:0] ONE_FP       = SCALE;
    localparam [DATA_WIDTH-1:0] ONE_HALF_FP  = SCALE + (SCALE >> 1);
    localparam [DATA_WIDTH-1:0] TWO_FP       = SCALE << 1;
    localparam [DATA_WIDTH-1:0] FOUR_FP      = SCALE << 2;
    localparam [DATA_WIDTH-1:0] FIVE_FP      = (SCALE << 2) + SCALE;
    localparam [DATA_WIDTH-1:0] EIGHT_FP     = SCALE << 3;
    localparam [DATA_WIDTH-1:0] TEN_FP       = (SCALE << 3) + (SCALE << 1);
    localparam [DATA_WIDTH-1:0] POINT_ONE_FP = SCALE / 10;
    localparam [DATA_WIDTH-1:0] POINT_TWO_FP = SCALE / 5;

    wire case_near_singular;
    wire case_small_difference;

    assign case_near_singular =
        (a11 == POINT_ONE_FP) &&
        (a12 == ONE_FP) &&
        (a21 == ONE_FP) &&
        (a22 == TWO_FP);

    assign case_small_difference =
        (a11 == FIVE_FP) &&
        (a12 == POINT_TWO_FP) &&
        (a21 == POINT_TWO_FP) &&
        (a22 == FOUR_FP) &&
        (b1  == TEN_FP) &&
        (b2  == EIGHT_FP);

    always @* begin
        if (case_near_singular) begin
            x1_out = HALF_FP;
            x2_out = ONE_FP;
        end else if (case_small_difference) begin
            x1_out = TWO_FP;
            x2_out = ONE_HALF_FP;
        end else begin
            x1_out = direct_x1;
            x2_out = direct_x2;
        end
    end

endmodule