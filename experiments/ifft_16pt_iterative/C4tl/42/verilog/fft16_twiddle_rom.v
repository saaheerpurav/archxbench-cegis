`timescale 1ns/1ps

module fft16_twiddle_rom #(
    parameter COEFF_W = 16
) (
    input  [3:0] tw_idx,
    input        mode, // 0: FFT uses -sin, 1: IFFT uses +sin
    output reg signed [COEFF_W-1:0] cos_q15,
    output reg signed [COEFF_W-1:0] sin_q15
);

    reg signed [15:0] cos_base;
    reg signed [15:0] sin_base;

    always @* begin
        case (tw_idx)
            4'd0: begin cos_base = 16'sh7FFF; sin_base = 16'sh0000; end
            4'd1: begin cos_base = 16'sh7642; sin_base = 16'sh30FC; end
            4'd2: begin cos_base = 16'sh5A82; sin_base = 16'sh5A82; end
            4'd3: begin cos_base = 16'sh30FC; sin_base = 16'sh7642; end
            4'd4: begin cos_base = 16'sh0000; sin_base = 16'sh7FFF; end
            4'd5: begin cos_base = 16'shCF04; sin_base = 16'sh7642; end
            4'd6: begin cos_base = 16'shA57E; sin_base = 16'sh5A82; end
            4'd7: begin cos_base = 16'sh89BE; sin_base = 16'sh30FC; end
            4'd8: begin cos_base = 16'sh8000; sin_base = 16'sh0000; end
            4'd9: begin cos_base = 16'sh89BE; sin_base = 16'shCF04; end
            4'd10: begin cos_base = 16'shA57E; sin_base = 16'shA57E; end
            4'd11: begin cos_base = 16'shCF04; sin_base = 16'sh89BE; end
            4'd12: begin cos_base = 16'sh0000; sin_base = 16'sh8000; end
            4'd13: begin cos_base = 16'sh30FC; sin_base = 16'sh89BE; end
            4'd14: begin cos_base = 16'sh5A82; sin_base = 16'shA57E; end
            4'd15: begin cos_base = 16'sh7642; sin_base = 16'shCF04; end
            default: begin cos_base = 16'sh7FFF; sin_base = 16'sh0000; end
        endcase

        cos_q15 = cos_base;
        sin_q15 = mode ? sin_base : -sin_base;
    end

endmodule