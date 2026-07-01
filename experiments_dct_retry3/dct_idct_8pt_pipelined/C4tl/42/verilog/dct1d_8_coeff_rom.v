`timescale 1ns/1ps

module dct1d_8_coeff_rom #(
    parameter COEFF_W = 16
) (
    input mode,
    input [2:0] out_index,
    output reg signed [COEFF_W-1:0] c0,
    output reg signed [COEFF_W-1:0] c1,
    output reg signed [COEFF_W-1:0] c2,
    output reg signed [COEFF_W-1:0] c3,
    output reg signed [COEFF_W-1:0] c4,
    output reg signed [COEFF_W-1:0] c5,
    output reg signed [COEFF_W-1:0] c6,
    output reg signed [COEFF_W-1:0] c7
);

    always @* begin
        c0 = 0; c1 = 0; c2 = 0; c3 = 0;
        c4 = 0; c5 = 0; c6 = 0; c7 = 0;

        if (!mode) begin
            case (out_index)
                3'd0: begin c0 = 5793; c1 = 5793; c2 = 5793; c3 = 5793; c4 = 5793; c5 = 5793; c6 = 5793; c7 = 5793; end
                3'd1: begin c0 = 8035; c1 = 6811; c2 = 4551; c3 = 1598; c4 = -1598; c5 = -4551; c6 = -6811; c7 = -8035; end
                3'd2: begin c0 = 7568; c1 = 3135; c2 = -3135; c3 = -7568; c4 = -7568; c5 = -3135; c6 = 3135; c7 = 7568; end
                3'd3: begin c0 = 6811; c1 = -1598; c2 = -8035; c3 = -4551; c4 = 4551; c5 = 8035; c6 = 1598; c7 = -6811; end
                3'd4: begin c0 = 5793; c1 = -5793; c2 = -5793; c3 = 5793; c4 = 5793; c5 = -5793; c6 = -5793; c7 = 5793; end
                3'd5: begin c0 = 4551; c1 = -8035; c2 = 1598; c3 = 6811; c4 = -6811; c5 = -1598; c6 = 8035; c7 = -4551; end
                3'd6: begin c0 = 3135; c1 = -7568; c2 = 7568; c3 = -3135; c4 = -3135; c5 = 7568; c6 = -7568; c7 = 3135; end
                3'd7: begin c0 = 1598; c1 = -4551; c2 = 6811; c3 = -8035; c4 = 8035; c5 = -6811; c6 = 4551; c7 = -1598; end
                default: begin end
            endcase
        end else begin
            case (out_index)
                3'd0: begin c0 = 5793; c1 = 8035; c2 = 7568; c3 = 6811; c4 = 5793; c5 = 4551; c6 = 3135; c7 = 1598; end
                3'd1: begin c0 = 5793; c1 = 6811; c2 = 3135; c3 = -1598; c4 = -5793; c5 = -8035; c6 = -7568; c7 = -4551; end
                3'd2: begin c0 = 5793; c1 = 4551; c2 = -3135; c3 = -8035; c4 = -5793; c5 = 1598; c6 = 7568; c7 = 6811; end
                3'd3: begin c0 = 5793; c1 = 1598; c2 = -7568; c3 = -4551; c4 = 5793; c5 = 6811; c6 = -3135; c7 = -8035; end
                3'd4: begin c0 = 5793; c1 = -1598; c2 = -7568; c3 = 4551; c4 = 5793; c5 = -6811; c6 = -3135; c7 = 8035; end
                3'd5: begin c0 = 5793; c1 = -4551; c2 = -3135; c3 = 8035; c4 = -5793; c5 = -1598; c6 = 7568; c7 = -6811; end
                3'd6: begin c0 = 5793; c1 = -6811; c2 = 3135; c3 = 1598; c4 = -5793; c5 = 8035; c6 = -7568; c7 = 4551; end
                3'd7: begin c0 = 5793; c1 = -8035; c2 = 7568; c3 = -6811; c4 = 5793; c5 = -4551; c6 = 3135; c7 = -1598; end
                default: begin end
            endcase
        end
    end

endmodule