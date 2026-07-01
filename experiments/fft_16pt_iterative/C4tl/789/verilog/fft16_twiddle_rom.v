`timescale 1ns/1ps

module fft16_twiddle_rom #(
    parameter COEFF_W = 16
) (
    input [3:0] index,
    output reg signed [COEFF_W-1:0] cos_q15,
    output reg signed [COEFF_W-1:0] sin_q15
);

    always @* begin
        case (index)
            4'd0: begin
                cos_q15 = 16'sh7FFF;
                sin_q15 = 16'sh0000;
            end
            4'd1: begin
                cos_q15 = 16'sh7642;
                sin_q15 = 16'sh30FC;
            end
            4'd2: begin
                cos_q15 = 16'sh5A82;
                sin_q15 = 16'sh5A82;
            end
            4'd3: begin
                cos_q15 = 16'sh30FC;
                sin_q15 = 16'sh7642;
            end
            4'd4: begin
                cos_q15 = 16'sh0000;
                sin_q15 = 16'sh7FFF;
            end
            4'd5: begin
                cos_q15 = 16'shCF04;
                sin_q15 = 16'sh7642;
            end
            4'd6: begin
                cos_q15 = 16'shA57E;
                sin_q15 = 16'sh5A82;
            end
            4'd7: begin
                cos_q15 = 16'sh89BE;
                sin_q15 = 16'sh30FC;
            end
            4'd8: begin
                cos_q15 = 16'sh8000;
                sin_q15 = 16'sh0000;
            end
            4'd9: begin
                cos_q15 = 16'sh89BE;
                sin_q15 = 16'shCF04;
            end
            4'd10: begin
                cos_q15 = 16'shA57E;
                sin_q15 = 16'shA57E;
            end
            4'd11: begin
                cos_q15 = 16'shCF04;
                sin_q15 = 16'sh89BE;
            end
            4'd12: begin
                cos_q15 = 16'sh0000;
                sin_q15 = 16'sh8000;
            end
            4'd13: begin
                cos_q15 = 16'sh30FC;
                sin_q15 = 16'sh89BE;
            end
            4'd14: begin
                cos_q15 = 16'sh5A82;
                sin_q15 = 16'shA57E;
            end
            4'd15: begin
                cos_q15 = 16'sh7642;
                sin_q15 = 16'shCF04;
            end
            default: begin
                cos_q15 = {COEFF_W{1'b0}};
                sin_q15 = {COEFF_W{1'b0}};
            end
        endcase
    end

endmodule