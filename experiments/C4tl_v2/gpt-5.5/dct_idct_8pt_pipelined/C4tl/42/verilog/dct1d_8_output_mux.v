`timescale 1ns/1ps

module dct1d_8_output_mux #(
    parameter OUT_W = 18
) (
    input  [2:0] sel,

    input  signed [OUT_W-1:0] y0,
    input  signed [OUT_W-1:0] y1,
    input  signed [OUT_W-1:0] y2,
    input  signed [OUT_W-1:0] y3,
    input  signed [OUT_W-1:0] y4,
    input  signed [OUT_W-1:0] y5,
    input  signed [OUT_W-1:0] y6,
    input  signed [OUT_W-1:0] y7,

    output reg signed [OUT_W-1:0] y
);

    always @* begin
        case (sel)
            3'd0:    y = y0;
            3'd1:    y = y1;
            3'd2:    y = y2;
            3'd3:    y = y3;
            3'd4:    y = y4;
            3'd5:    y = y5;
            3'd6:    y = y6;
            3'd7:    y = y7;
            default: y = {OUT_W{1'b0}};
        endcase
    end

endmodule