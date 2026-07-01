`timescale 1ns/1ps

module dct1d_8_saturate #(
    parameter IN_W  = 32,
    parameter OUT_W = 18
) (
    input  signed [IN_W-1:0] in_value,
    output reg    [OUT_W-1:0] out_value
);

    localparam signed [IN_W-1:0] MAX_VAL =
        {{(IN_W-OUT_W){1'b0}}, 1'b0, {(OUT_W-1){1'b1}}};

    localparam signed [IN_W-1:0] MIN_VAL =
        {{(IN_W-OUT_W){1'b1}}, 1'b1, {(OUT_W-1){1'b0}}};

    always @* begin
        if (in_value > MAX_VAL) begin
            out_value = {1'b0, {(OUT_W-1){1'b1}}};
        end else if (in_value < MIN_VAL) begin
            out_value = {1'b1, {(OUT_W-1){1'b0}}};
        end else begin
            out_value = in_value[OUT_W-1:0];
        end
    end

endmodule