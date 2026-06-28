`timescale 1ns/1ps

module fir_tap_shift_next #(
    parameter DATA_W  = 20,
    parameter TAP_CNT = 101
) (
    input      [DATA_W-1:0]         data_in,
    input      [DATA_W*TAP_CNT-1:0] taps_cur,
    output     [DATA_W*TAP_CNT-1:0] taps_next
);

    // The flattened tap layout is:
    //   tap i == vector[i*DATA_W +: DATA_W]
    //
    // Next-state delay-line behavior:
    //   tap 0 receives the newest sample
    //   tap i receives previous tap i-1

    assign taps_next[0 +: DATA_W] = data_in;

    genvar i;
    generate
        for (i = 1; i < TAP_CNT; i = i + 1) begin : g_shift
            assign taps_next[i*DATA_W +: DATA_W] =
                   taps_cur[(i-1)*DATA_W +: DATA_W];
        end
    endgenerate

endmodule