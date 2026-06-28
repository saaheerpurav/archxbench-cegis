`timescale 1ns/1ps

module fft16_twiddle_rom #(
    parameter N       = 16,
    parameter COEFF_W = 16,
    parameter ADDR_W  = 4
) (
    input  [ADDR_W-1:0] tw_index,
    output reg signed [COEFF_W-1:0] cos_q15,
    output reg signed [COEFF_W-1:0] sin_q15
);

    /*
        Q1.15 twiddle coefficient ROM for N = 16.

        Stored convention:
            cos_q15[k] = round(cos(2*pi*k/N) * 32768), clipped
            sin_q15[k] = round(sin(2*pi*k/N) * 32768), clipped

        FFT butterfly convention uses:
            W[k] = cos_q15[k] - j*sin_q15[k]

        IFFT should conjugate externally by negating the imaginary twiddle
        component.
    */

    always @* begin
        case (tw_index)
            4'd0: begin
                cos_q15 =  32767;   // 0x7FFF
                sin_q15 =      0;   // 0x0000
            end

            4'd1: begin
                cos_q15 =  30274;   // 0x7642
                sin_q15 =  12540;   // 0x30FC
            end

            4'd2: begin
                cos_q15 =  23170;   // 0x5A82
                sin_q15 =  23170;   // 0x5A82
            end

            4'd3: begin
                cos_q15 =  12540;   // 0x30FC
                sin_q15 =  30274;   // 0x7642
            end

            4'd4: begin
                cos_q15 =      0;   // 0x0000
                sin_q15 =  32767;   // 0x7FFF, +1.0 clipped
            end

            4'd5: begin
                cos_q15 = -12540;   // 0xCF04
                sin_q15 =  30274;   // 0x7642
            end

            4'd6: begin
                cos_q15 = -23170;   // 0xA57E
                sin_q15 =  23170;   // 0x5A82
            end

            4'd7: begin
                cos_q15 = -30274;   // 0x89BE
                sin_q15 =  12540;   // 0x30FC
            end

            4'd8: begin
                cos_q15 = -32768;   // 0x8000, -1.0 exactly representable
                sin_q15 =      0;   // 0x0000
            end

            4'd9: begin
                cos_q15 = -30274;   // 0x89BE
                sin_q15 = -12540;   // 0xCF04
            end

            4'd10: begin
                cos_q15 = -23170;   // 0xA57E
                sin_q15 = -23170;   // 0xA57E
            end

            4'd11: begin
                cos_q15 = -12540;   // 0xCF04
                sin_q15 = -30274;   // 0x89BE
            end

            4'd12: begin
                cos_q15 =      0;   // 0x0000
                sin_q15 = -32768;   // 0x8000, -1.0 exactly representable
            end

            4'd13: begin
                cos_q15 =  12540;   // 0x30FC
                sin_q15 = -30274;   // 0x89BE
            end

            4'd14: begin
                cos_q15 =  23170;   // 0x5A82
                sin_q15 = -23170;   // 0xA57E
            end

            4'd15: begin
                cos_q15 =  30274;   // 0x7642
                sin_q15 = -12540;   // 0xCF04
            end

            default: begin
                cos_q15 =  32767;
                sin_q15 =      0;
            end
        endcase
    end

endmodule