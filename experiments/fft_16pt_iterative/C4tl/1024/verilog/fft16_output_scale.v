module fft16_output_scale #(
    parameter OUT_W = 16,
    parameter GAIN_W = 4
) (
    input mode,
    input signed [OUT_W-1:0] real_in,
    input signed [OUT_W-1:0] imag_in,
    output signed [OUT_W-1:0] real_out,
    output signed [OUT_W-1:0] imag_out
);
    assign real_out = mode ? (real_in >>> GAIN_W) : real_in;
    assign imag_out = mode ? (imag_in >>> GAIN_W) : imag_in;
endmodule