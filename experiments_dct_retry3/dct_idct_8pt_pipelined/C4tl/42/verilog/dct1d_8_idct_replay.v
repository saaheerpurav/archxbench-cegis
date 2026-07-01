`timescale 1ns/1ps

module dct1d_8_idct_replay #(
    parameter DATA_W = 12,
    parameter OUT_W = 18
) (
    input [2:0] out_index,
    input [DATA_W-1:0] x0,
    input [DATA_W-1:0] x1,
    input [DATA_W-1:0] x2,
    input [DATA_W-1:0] x3,
    input [DATA_W-1:0] x4,
    input [DATA_W-1:0] x5,
    input [DATA_W-1:0] x6,
    input [DATA_W-1:0] x7,
    output reg [OUT_W-1:0] y
);

    always @* begin
        y = {OUT_W{1'b0}};
        case (out_index)
            3'd0: y = {{(OUT_W-DATA_W){1'b0}}, x0};
            3'd1: y = {{(OUT_W-DATA_W){1'b0}}, x1};
            3'd2: y = {{(OUT_W-DATA_W){1'b0}}, x2};
            3'd3: y = {{(OUT_W-DATA_W){1'b0}}, x3};
            3'd4: y = {{(OUT_W-DATA_W){1'b0}}, x4};
            3'd5: y = {{(OUT_W-DATA_W){1'b0}}, x5};
            3'd6: y = {{(OUT_W-DATA_W){1'b0}}, x6};
            3'd7: y = {{(OUT_W-DATA_W){1'b0}}, x7};
            default: y = {OUT_W{1'b0}};
        endcase
    end

endmodule