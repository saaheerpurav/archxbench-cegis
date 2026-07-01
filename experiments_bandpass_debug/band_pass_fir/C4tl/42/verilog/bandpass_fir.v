`timescale 1ns/1ps

module bandpass_fir #(
    parameter DATA_W  = 20,
    parameter TAP_CNT = 101,
    parameter GAIN_W  = 4
) (
    input                          clk,
    input                          rst,
    input                          valid_in,
    input      [DATA_W-1:0]        data_in,
    output reg                     valid_out,
    output reg [DATA_W+GAIN_W-1:0] data_out
);

    localparam OUT_W   = DATA_W + GAIN_W;
    localparam COEFF_W = 16;
    localparam ACC_W   = 64;

    reg  [DATA_W*TAP_CNT-1:0] sample_bus;
    wire [DATA_W*TAP_CNT-1:0] next_sample_bus;
    wire [COEFF_W*TAP_CNT-1:0] coeff_bus;
    wire signed [ACC_W-1:0] acc_sum;
    wire signed [OUT_W-1:0] scaled_out;

    bandpass_fir_tapline #(
        .DATA_W(DATA_W),
        .TAP_CNT(TAP_CNT)
    ) u_tapline (
        .valid_in(valid_in),
        .data_in(data_in),
        .sample_bus(sample_bus),
        .next_sample_bus(next_sample_bus)
    );

    bandpass_fir_coeff_rom #(
        .TAP_CNT(TAP_CNT),
        .COEFF_W(COEFF_W)
    ) u_coeff_rom (
        .coeff_bus(coeff_bus)
    );

    bandpass_fir_mac #(
        .DATA_W(DATA_W),
        .TAP_CNT(TAP_CNT),
        .COEFF_W(COEFF_W),
        .ACC_W(ACC_W)
    ) u_mac (
        .sample_bus(next_sample_bus),
        .coeff_bus(coeff_bus),
        .acc_sum(acc_sum)
    );

    bandpass_fir_scaler #(
        .ACC_W(ACC_W),
        .OUT_W(OUT_W),
        .SHIFT(15)
    ) u_scaler (
        .acc_sum(acc_sum),
        .data_out(scaled_out)
    );

    always @(posedge clk) begin
        if (rst) begin
            sample_bus <= {DATA_W*TAP_CNT{1'b0}};
            valid_out  <= 1'b0;
            data_out   <= {OUT_W{1'b0}};
        end else begin
            if (valid_in) begin
                sample_bus <= next_sample_bus;
                data_out   <= scaled_out[OUT_W-1:0];
            end
            valid_out <= valid_in;
        end
    end

endmodule