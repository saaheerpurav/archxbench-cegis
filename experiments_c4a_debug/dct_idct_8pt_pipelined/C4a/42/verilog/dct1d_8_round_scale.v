`timescale 1ns/1ps

module dct1d_8_round_scale #(
    parameter IN_W  = 18,
    parameter OUT_W = 18
) (
    input  signed [IN_W-1:0]  din,
    output signed [OUT_W-1:0] dout
);

generate
    if (OUT_W >= IN_W) begin : gen_sign_extend
        assign dout = {{(OUT_W-IN_W){din[IN_W-1]}}, din};
    end else begin : gen_truncate
        assign dout = din[OUT_W-1:0];
    end
endgenerate

endmodule