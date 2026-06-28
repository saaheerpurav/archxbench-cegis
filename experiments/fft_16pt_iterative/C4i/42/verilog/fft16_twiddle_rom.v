`timescale 1ns/1ps

module fft16_twiddle_rom #(
    parameter N = 16,
    parameter COEFF_W = 16
) (
    input  [$clog2(N)-1:0] twiddle_idx,
    output reg signed [COEFF_W-1:0] cos_q15,
    output reg signed [COEFF_W-1:0] sin_q15
);

    always @(*) begin
        case (twiddle_idx)
            4'd0: begin
                cos_q15 = 16'sd32767;
                sin_q15 = 16'sd0;
            end

            4'd1: begin
                cos_q15 = 16'sd30274;
                sin_q15 = 16'sd12540;
            end

            4'd2: begin
                cos_q15 = 16'sd23170;
                sin_q15 = 16'sd23170;
            end

            4'd3: begin
                cos_q15 = 16'sd12540;
                sin_q15 = 16'sd30274;
            end

            4'd4: begin
                cos_q15 = 16'sd0;
                sin_q15 = 16'sd32767;
            end

            4'd5: begin
                cos_q15 = -16'sd12540;
                sin_q15 = 16'sd30274;
            end

            4'd6: begin
                cos_q15 = -16'sd23170;
                sin_q15 = 16'sd23170;
            end

            4'd7: begin
                cos_q15 = -16'sd30274;
                sin_q15 = 16'sd12540;
            end

            4'd8: begin
                cos_q15 = 16'sh8000;   // -32768
                sin_q15 = 16'sd0;
            end

            4'd9: begin
                cos_q15 = -16'sd30274;
                sin_q15 = -16'sd12540;
            end

            4'd10: begin
                cos_q15 = -16'sd23170;
                sin_q15 = -16'sd23170;
            end

            4'd11: begin
                cos_q15 = -16'sd12540;
                sin_q15 = -16'sd30274;
            end

            4'd12: begin
                cos_q15 = 16'sd0;
                sin_q15 = 16'sh8000;   // -32768
            end

            4'd13: begin
                cos_q15 = 16'sd12540;
                sin_q15 = -16'sd30274;
            end

            4'd14: begin
                cos_q15 = 16'sd23170;
                sin_q15 = -16'sd23170;
            end

            4'd15: begin
                cos_q15 = 16'sd30274;
                sin_q15 = -16'sd12540;
            end

            default: begin
                cos_q15 = 16'sd32767;
                sin_q15 = 16'sd0;
            end
        endcase
    end

endmodule