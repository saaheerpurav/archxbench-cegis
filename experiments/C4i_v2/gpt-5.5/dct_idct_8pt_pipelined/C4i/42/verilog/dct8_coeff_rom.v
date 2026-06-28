`timescale 1ns/1ps

module dct8_coeff_rom #(
    parameter COEFF_W = 16
) (
    input  wire                      mode,
    input  wire [2:0]                row_index,
    input  wire [2:0]                col_index,
    output reg  signed [COEFF_W-1:0] coeff
);

    /*
     * Combinational Q2.14 orthonormal 8-point DCT coefficient ROM.
     *
     * DCT mode, mode = 0:
     *   coeff = C[row_index][col_index]
     *
     * IDCT mode, mode = 1:
     *   coeff = C[col_index][row_index]
     */

    wire [2:0] k_sel;
    wire [2:0] n_sel;

    assign k_sel = (mode == 1'b0) ? row_index : col_index;
    assign n_sel = (mode == 1'b0) ? col_index : row_index;

    always @* begin
        coeff = {COEFF_W{1'b0}};

        case (k_sel)
            3'd0: begin
                case (n_sel)
                    3'd0: coeff = 16'sd5793;
                    3'd1: coeff = 16'sd5793;
                    3'd2: coeff = 16'sd5793;
                    3'd3: coeff = 16'sd5793;
                    3'd4: coeff = 16'sd5793;
                    3'd5: coeff = 16'sd5793;
                    3'd6: coeff = 16'sd5793;
                    3'd7: coeff = 16'sd5793;
                    default: coeff = {COEFF_W{1'b0}};
                endcase
            end

            3'd1: begin
                case (n_sel)
                    3'd0: coeff =  16'sd8035;
                    3'd1: coeff =  16'sd6811;
                    3'd2: coeff =  16'sd4551;
                    3'd3: coeff =  16'sd1598;
                    3'd4: coeff = -16'sd1598;
                    3'd5: coeff = -16'sd4551;
                    3'd6: coeff = -16'sd6811;
                    3'd7: coeff = -16'sd8035;
                    default: coeff = {COEFF_W{1'b0}};
                endcase
            end

            3'd2: begin
                case (n_sel)
                    3'd0: coeff =  16'sd7568;
                    3'd1: coeff =  16'sd3135;
                    3'd2: coeff = -16'sd3135;
                    3'd3: coeff = -16'sd7568;
                    3'd4: coeff = -16'sd7568;
                    3'd5: coeff = -16'sd3135;
                    3'd6: coeff =  16'sd3135;
                    3'd7: coeff =  16'sd7568;
                    default: coeff = {COEFF_W{1'b0}};
                endcase
            end

            3'd3: begin
                case (n_sel)
                    3'd0: coeff =  16'sd6811;
                    3'd1: coeff = -16'sd1598;
                    3'd2: coeff = -16'sd8035;
                    3'd3: coeff = -16'sd4551;
                    3'd4: coeff =  16'sd4551;
                    3'd5: coeff =  16'sd8035;
                    3'd6: coeff =  16'sd1598;
                    3'd7: coeff = -16'sd6811;
                    default: coeff = {COEFF_W{1'b0}};
                endcase
            end

            3'd4: begin
                case (n_sel)
                    3'd0: coeff =  16'sd5793;
                    3'd1: coeff = -16'sd5793;
                    3'd2: coeff = -16'sd5793;
                    3'd3: coeff =  16'sd5793;
                    3'd4: coeff =  16'sd5793;
                    3'd5: coeff = -16'sd5793;
                    3'd6: coeff = -16'sd5793;
                    3'd7: coeff =  16'sd5793;
                    default: coeff = {COEFF_W{1'b0}};
                endcase
            end

            3'd5: begin
                case (n_sel)
                    3'd0: coeff =  16'sd4551;
                    3'd1: coeff = -16'sd8035;
                    3'd2: coeff =  16'sd1598;
                    3'd3: coeff =  16'sd6811;
                    3'd4: coeff = -16'sd6811;
                    3'd5: coeff = -16'sd1598;
                    3'd6: coeff =  16'sd8035;
                    3'd7: coeff = -16'sd4551;
                    default: coeff = {COEFF_W{1'b0}};
                endcase
            end

            3'd6: begin
                case (n_sel)
                    3'd0: coeff =  16'sd3135;
                    3'd1: coeff = -16'sd7568;
                    3'd2: coeff =  16'sd7568;
                    3'd3: coeff = -16'sd3135;
                    3'd4: coeff = -16'sd3135;
                    3'd5: coeff =  16'sd7568;
                    3'd6: coeff = -16'sd7568;
                    3'd7: coeff =  16'sd3135;
                    default: coeff = {COEFF_W{1'b0}};
                endcase
            end

            3'd7: begin
                case (n_sel)
                    3'd0: coeff =  16'sd1598;
                    3'd1: coeff = -16'sd4551;
                    3'd2: coeff =  16'sd6811;
                    3'd3: coeff = -16'sd8035;
                    3'd4: coeff =  16'sd8035;
                    3'd5: coeff = -16'sd6811;
                    3'd6: coeff =  16'sd4551;
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