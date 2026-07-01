module fft16_twiddle_mode #(
    parameter COEFF_W = 16
) (
    input mode,
    input signed [COEFF_W-1:0] sin_q15_in,
    output signed [COEFF_W-1:0] sin_q15_eff
);
    // FFT uses W = cos - j*sin. IFFT uses the conjugate, so negate sin.
    assign sin_q15_eff = mode ? -sin_q15_in : sin_q15_in;
endmodule