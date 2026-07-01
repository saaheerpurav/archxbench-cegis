`timescale 1ns/1ps

module dct1d_8_saturate #(
    parameter IN_W  = 18,
    parameter OUT_W = 18
) (
    input  signed [IN_W-1:0]  din,
    output signed [OUT_W-1:0] dout
);

generate
    if (IN_W > OUT_W) begin : gen_saturate
        localparam signed [OUT_W-1:0] MAX_OUT = {1'b0, {(OUT_W-1){1'b1}}};
        localparam signed [OUT_W-1:0] MIN_OUT = {1'b1, {(OUT_W-1){1'b0}}};

        wire signed [IN_W-1:0] max_ext =
            {{(IN_W-OUT_W){MAX_OUT[OUT_W-1]}}, MAX_OUT};
        wire signed [IN_W-1:0] min_ext =
            {{(IN_W-OUT_W){MIN_OUT[OUT_W-1]}}, MIN_OUT};

        assign dout = (din > max_ext) ? MAX_OUT :
                      (din < min_ext) ? MIN_OUT :
                      din[OUT_W-1:0];
    end else if (IN_W < OUT_W) begin : gen_extend
        assign dout = {{(OUT_W-IN_W){din[IN_W-1]}}, din};
    end else begin : gen_passthrough
        assign dout = din;
    end
endgenerate

endmodule