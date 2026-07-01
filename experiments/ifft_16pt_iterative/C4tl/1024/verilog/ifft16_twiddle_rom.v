`timescale 1ns/1ps

module ifft16_twiddle_rom #(
    parameter COEFF_W = 16
) (
    input  [3:0] idx,
    input  ifft_mode,
    output reg signed [COEFF_W-1:0] cos_o,
    output reg signed [COEFF_W-1:0] sin_o
);
    reg signed [COEFF_W-1:0] sin_pos;

    always @* begin
        case (idx)
            4'd0: begin cos_o = 16'sd32767;  sin_pos = 16'sd0;      end
            4'd1: begin cos_o = 16'sd30274;  sin_pos = 16'sd12540;  end
            4'd2: begin cos_o = 16'sd23170;  sin_pos = 16'sd23170;  end
            4'd3: begin cos_o = 16'sd12540;  sin_pos = 16'sd30274;  end
            4'd4: begin cos_o = 16'sd0;      sin_pos = 16'sd32767;  end
            4'd5: begin cos_o = -16'sd12540; sin_pos = 16'sd30274;  end
            4'd6: begin cos_o = -16'sd23170; sin_pos = 16'sd23170;  end
            4'd7: begin cos_o = -16'sd30274; sin_pos = 16'sd12540;  end
            4'd8: begin cos_o = -16'sd32768; sin_pos = 16'sd0;      end
            default: begin cos_o = 16'sd32767; sin_pos = 16'sd0;    end
        endcase

        if (ifft_mode)
            sin_o = sin_pos;
        else
            sin_o = -sin_pos;
    end
endmodule