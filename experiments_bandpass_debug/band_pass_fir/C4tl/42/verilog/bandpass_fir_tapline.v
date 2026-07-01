`timescale 1ns/1ps

module bandpass_fir_tapline #(
    parameter DATA_W  = 20,
    parameter TAP_CNT = 101
) (
    input                           valid_in,
    input      [DATA_W-1:0]         data_in,
    input      [DATA_W*TAP_CNT-1:0] sample_bus,
    output reg [DATA_W*TAP_CNT-1:0] next_sample_bus
);

    integer i;

    always @* begin
        next_sample_bus = sample_bus;

        if (valid_in) begin
            next_sample_bus[DATA_W-1:0] = data_in;

            for (i = 1; i < TAP_CNT; i = i + 1) begin
                next_sample_bus[i*DATA_W +: DATA_W] =
                    sample_bus[(i-1)*DATA_W +: DATA_W];
            end
        end
    end

endmodule