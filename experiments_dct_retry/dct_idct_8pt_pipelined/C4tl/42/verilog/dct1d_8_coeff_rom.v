`timescale 1ns/1ps

module dct1d_8_coeff_rom #(
    parameter COEFF_W = 16
) (
    input  wire                    mode,
    input  wire [2:0]              out_index,
    input  wire [2:0]              in_index,
    output reg  signed [COEFF_W-1:0] coeff
);

    function signed [15:0] dct_coeff;
        input [2:0] k;
        input [2:0] n;
        begin
            case ({k,n})
                6'o00, 6'o01, 6'o02, 6'o03,
                6'o04, 6'o05, 6'o06, 6'o07: dct_coeff = 16'sd5793;

                6'o10: dct_coeff =  16'sd8035;
                6'o11: dct_coeff =  16'sd6811;
                6'o12: dct_coeff =  16'sd4551;
                6'o13: dct_coeff =  16'sd1598;
                6'o14: dct_coeff = -16'sd1598;
                6'o15: dct_coeff = -16'sd4551;
                6'o16: dct_coeff = -16'sd6811;
                6'o17: dct_coeff = -16'sd8035;

                6'o20: dct_coeff =  16'sd7568;
                6'o21: dct_coeff =  16'sd3135;
                6'o22: dct_coeff = -16'sd3135;
                6'o23: dct_coeff = -16'sd7568;
                6'o24: dct_coeff = -16'sd7568;
                6'o25: dct_coeff = -16'sd3135;
                6'o26: dct_coeff =  16'sd3135;
                6'o27: dct_coeff =  16'sd7568;

                6'o30: dct_coeff =  16'sd6811;
                6'o31: dct_coeff = -16'sd1598;
                6'o32: dct_coeff = -16'sd8035;
                6'o33: dct_coeff = -16'sd4551;
                6'o34: dct_coeff =  16'sd4551;
                6'o35: dct_coeff =  16'sd8035;
                6'o36: dct_coeff =  16'sd1598;
                6'o37: dct_coeff = -16'sd6811;

                6'o40: dct_coeff =  16'sd5793;
                6'o41: dct_coeff = -16'sd5793;
                6'o42: dct_coeff = -16'sd5793;
                6'o43: dct_coeff =  16'sd5793;
                6'o44: dct_coeff =  16'sd5793;
                6'o45: dct_coeff = -16'sd5793;
                6'o46: dct_coeff = -16'sd5793;
                6'o47: dct_coeff =  16'sd5793;

                6'o50: dct_coeff =  16'sd4551;
                6'o51: dct_coeff = -16'sd8035;
                6'o52: dct_coeff =  16'sd1598;
                6'o53: dct_coeff =  16'sd6811;
                6'o54: dct_coeff = -16'sd6811;
                6'o55: dct_coeff = -16'sd1598;
                6'o56: dct_coeff =  16'sd8035;
                6'o57: dct_coeff = -16'sd4551;

                6'o60: dct_coeff =  16'sd3135;
                6'o61: dct_coeff = -16'sd7568;
                6'o62: dct_coeff =  16'sd7568;
                6'o63: dct_coeff = -16'sd3135;
                6'o64: dct_coeff = -16'sd3135;
                6'o65: dct_coeff =  16'sd7568;
                6'o66: dct_coeff = -16'sd7568;
                6'o67: dct_coeff =  16'sd3135;

                6'o70: dct_coeff =  16'sd1598;
                6'o71: dct_coeff = -16'sd4551;
                6'o72: dct_coeff =  16'sd6811;
                6'o73: dct_coeff = -16'sd8035;
                6'o74: dct_coeff =  16'sd8035;
                6'o75: dct_coeff = -16'sd6811;
                6'o76: dct_coeff =  16'sd4551;
                6'o77: dct_coeff = -16'sd1598;

                default: dct_coeff = 16'sd0;
            endcase
        end
    endfunction

    function signed [COEFF_W-1:0] resize_coeff;
        input signed [15:0] v;
        begin
            if (COEFF_W >= 16)
                resize_coeff = {{(COEFF_W-16){v[15]}}, v};
            else
                resize_coeff = v[15 -: COEFF_W];
        end
    endfunction

    always @* begin
        coeff = mode ? resize_coeff(dct_coeff(in_index, out_index))
                     : resize_coeff(dct_coeff(out_index, in_index));
    end

endmodule