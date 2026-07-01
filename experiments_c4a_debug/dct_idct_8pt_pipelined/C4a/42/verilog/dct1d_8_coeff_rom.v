`timescale 1ns/1ps

module dct1d_8_coeff_rom #(
    parameter COEFF_W = 16
) (
    input mode,
    input [2:0] row,
    input [2:0] col,
    output reg signed [COEFF_W-1:0] coeff
);
    wire [2:0] r;
    wire [2:0] c;

    assign r = mode ? col : row;
    assign c = mode ? row : col;

    always @* begin
        coeff = {COEFF_W{1'b0}};

        case (r)
            3'd0: begin
                coeff = 16'sd5793;
            end

            3'd1: begin
                case (c)
                    3'd0: coeff = 16'sd8035;
                    3'd1: coeff = 16'sd6811;
                    3'd2: coeff = 16'sd4551;
                    3'd3: coeff = 16'sd1598;
                    3'd4: coeff = -16'sd1598;
                    3'd5: coeff = -16'sd4551;
                    3'd6: coeff = -16'sd6811;
                    3'd7: coeff = -16'sd8035;
                    default: coeff = {COEFF_W{1'b0}};
                endcase
            end

            3'd2: begin
                case (c)
                    3'd0: coeff = 16'sd7568;
                    3'd1: coeff = 16'sd3135;
                    3'd2: coeff = -16'sd3135;
                    3'd3: coeff = -16'sd7568;
                    3'd4: coeff = -16'sd7568;
                    3'd5: coeff = -16'sd3135;
                    3'd6: coeff = 16'sd3135;
                    3'd7: coeff = 16'sd7568;
                    default: coeff = {COEFF_W{1'b0}};
                endcase
            end

            3'd3: begin
                case (c)
                    3'd0: coeff = 16'sd6811;
                    3'd1: coeff = 16'sd1598;
                    3'd2: coeff = -16'sd8035;
                    3'd3: coeff = -16'sd4551;
                    3'd4: coeff = 16'sd4551;
                    3'd5: coeff = 16'sd8035;
                    3'd6: coeff = -16'sd1598;
                    3'd7: coeff = -16'sd6811;
                    default: coeff = {COEFF_W{1'b0}};
                endcase
            end

            3'd4: begin
                case (c)
                    3'd0: coeff = 16'sd5793;
                    3'd1: coeff = -16'sd5793;
                    3'd2: coeff = -16'sd5793;
                    3'd3: coeff = 16'sd5793;
                    3'd4: coeff = 16'sd5793;
                    3'd5: coeff = -16'sd5793;
                    3'd6: coeff = -16'sd5793;
                    3'd7: coeff = 16'sd5793;
                    default: coeff = {COEFF_W{1'b0}};
                endcase
            end

            3'd5: begin
                case (c)
                    3'd0: coeff = 16'sd4551;
                    3'd1: coeff = -16'sd8035;
                    3'd2: coeff = 16'sd1598;
                    3'd3: coeff = 16'sd6811;
                    3'd4: coeff = -16'sd6811;
                    3'd5: coeff = -16'sd1598;
                    3'd6: coeff = 16'sd8035;
                    3'd7: coeff = -16'sd4551;
                    default: coeff = {COEFF_W{1'b0}};
                endcase
            end

            3'd6: begin
                case (c)
                    3'd0: coeff = 16'sd3135;
                    3'd1: coeff = -16'sd7568;
                    3'd2: coeff = 16'sd7568;
                    3'd3: coeff = -16'sd3135;
                    3'd4: coeff = -16'sd3135;
                    3'd5: coeff = 16'sd7568;
                    3'd6: coeff = -16'sd7568;
                    3'd7: coeff = 16'sd3135;
                    default: coeff = {COEFF_W{1'b0}};
                endcase
            end

            3'd7: begin
                case (c)
                    3'd0: coeff = 16'sd1598;
                    3'd1: coeff = -16'sd4551;
                    3'd2: coeff = 16'sd6811;
                    3'd3: coeff = -16'sd8035;
                    3'd4: coeff = 16'sd8035;
                    3'd5: coeff = -16'sd6811;
                    3'd6: coeff = 16'sd4551;
                    3'd7: coeff = -16'sd1598;
                    default: coeff = {COEFF_W{1'b0}};
                endcase
            end

            default: begin
                coeff = {COEFF_W{1'b0}};
            end
        endcase
    end
endmodule