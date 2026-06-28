`timescale 1ns/1ps

module ifft16_twiddle_rom #(
    parameter N       = 16,
    parameter COEFF_W = 16,
    parameter IDX_W   = 4
) (
    input  [IDX_W-1:0] idx,
    output reg signed [COEFF_W-1:0] cos_q15,
    output reg signed [COEFF_W-1:0] sin_q15
);

    always @* begin
        case (idx)
            4'd0: begin
                cos_q15 = 16'sh7FFF; //  32767,  cos(0)
                sin_q15 = 16'sh0000; //      0,  sin(0)
            end

            4'd1: begin
                cos_q15 = 16'sh7642; //  30274,  cos(pi/8)
                sin_q15 = 16'sh30FC; //  12540,  sin(pi/8)
            end

            4'd2: begin
                cos_q15 = 16'sh5A82; //  23170,  cos(pi/4)
                sin_q15 = 16'sh5A82; //  23170,  sin(pi/4)
            end

            4'd3: begin
                cos_q15 = 16'sh30FC; //  12540,  cos(3pi/8)
                sin_q15 = 16'sh7642; //  30274,  sin(3pi/8)
            end

            4'd4: begin
                cos_q15 = 16'sh0000; //      0,  cos(pi/2)
                sin_q15 = 16'sh7FFF; //  32767,  sin(pi/2), clipped from +1.0
            end

            4'd5: begin
                cos_q15 = 16'shCF04; // -12540,  cos(5pi/8)
                sin_q15 = 16'sh7642; //  30274,  sin(5pi/8)
            end

            4'd6: begin
                cos_q15 = 16'shA57E; // -23170,  cos(6pi/8)
                sin_q15 = 16'sh5A82; //  23170,  sin(6pi/8)
            end

            4'd7: begin
                cos_q15 = 16'sh89BE; // -30274,  cos(7pi/8)
                sin_q15 = 16'sh30FC; //  12540,  sin(7pi/8)
            end

            4'd8: begin
                cos_q15 = 16'sh8000; // -32768,  cos(pi)
                sin_q15 = 16'sh0000; //      0,  sin(pi)
            end

            default: begin
                cos_q15 = 16'sh7FFF;
                sin_q15 = 16'sh0000;
            end
        endcase
    end

endmodule