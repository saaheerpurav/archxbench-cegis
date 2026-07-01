`timescale 1ns/1ps

module conv3d_output_format #(
    parameter IN_W  = 28,
    parameter OUT_W = 12
) (
    input  [IN_W-1:0]  sum_in,
    output [OUT_W-1:0] voxel_out
);

generate
    if (OUT_W <= IN_W) begin : gen_truncate
        assign voxel_out = sum_in[OUT_W-1:0];
    end else begin : gen_zero_extend
        assign voxel_out = {{(OUT_W-IN_W){1'b0}}, sum_in};
    end
endgenerate

endmodule