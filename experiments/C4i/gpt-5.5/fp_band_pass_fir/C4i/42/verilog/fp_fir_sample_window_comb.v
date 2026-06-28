`timescale 1ns/1ps

module fp_fir_sample_window_comb #(
    parameter TAP_CNT = 63
) (
    input  [TAP_CNT*32-1:0] samples_flat_in,
    input                   valid_in,
    input  [31:0]           data_in,
    output [TAP_CNT*32-1:0] samples_flat_out
);

    genvar i;

    generate
        for (i = 0; i < TAP_CNT; i = i + 1) begin : GEN_SAMPLE_WINDOW
            if (i == 0) begin : GEN_INSERT_NEW_SAMPLE
                assign samples_flat_out[i*32 +: 32] =
                    valid_in ? data_in : 32'h00000000;
            end else begin : GEN_SHIFT_OLDER_SAMPLE
                assign samples_flat_out[i*32 +: 32] =
                    samples_flat_in[(i-1)*32 +: 32];
            end
        end
    endgenerate

endmodule