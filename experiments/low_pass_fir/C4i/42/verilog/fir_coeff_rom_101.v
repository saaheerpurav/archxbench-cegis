`timescale 1ns/1ps

module fir_coeff_rom_101 #(
    parameter COEFF_W  = 16,
    parameter PAIR_CNT = 50
) (
    output reg [COEFF_W*PAIR_CNT-1:0] pair_coeffs,
    output reg signed [COEFF_W-1:0]   center_coeff
);

    always @* begin
        pair_coeffs = {COEFF_W*PAIR_CNT{1'b0}};

        pair_coeffs[0*COEFF_W  +: COEFF_W] = 16'sd0;
        pair_coeffs[1*COEFF_W  +: COEFF_W] = -16'sd2;
        pair_coeffs[2*COEFF_W  +: COEFF_W] = -16'sd5;
        pair_coeffs[3*COEFF_W  +: COEFF_W] = -16'sd7;
        pair_coeffs[4*COEFF_W  +: COEFF_W] = -16'sd10;
        pair_coeffs[5*COEFF_W  +: COEFF_W] = -16'sd14;
        pair_coeffs[6*COEFF_W  +: COEFF_W] = -16'sd18;
        pair_coeffs[7*COEFF_W  +: COEFF_W] = -16'sd23;
        pair_coeffs[8*COEFF_W  +: COEFF_W] = -16'sd29;
        pair_coeffs[9*COEFF_W  +: COEFF_W] = -16'sd35;
        pair_coeffs[10*COEFF_W +: COEFF_W] = -16'sd41;
        pair_coeffs[11*COEFF_W +: COEFF_W] = -16'sd49;
        pair_coeffs[12*COEFF_W +: COEFF_W] = -16'sd56;
        pair_coeffs[13*COEFF_W +: COEFF_W] = -16'sd63;
        pair_coeffs[14*COEFF_W +: COEFF_W] = -16'sd70;
        pair_coeffs[15*COEFF_W +: COEFF_W] = -16'sd76;
        pair_coeffs[16*COEFF_W +: COEFF_W] = -16'sd81;
        pair_coeffs[17*COEFF_W +: COEFF_W] = -16'sd85;
        pair_coeffs[18*COEFF_W +: COEFF_W] = -16'sd86;
        pair_coeffs[19*COEFF_W +: COEFF_W] = -16'sd85;
        pair_coeffs[20*COEFF_W +: COEFF_W] = -16'sd81;
        pair_coeffs[21*COEFF_W +: COEFF_W] = -16'sd73;
        pair_coeffs[22*COEFF_W +: COEFF_W] = -16'sd62;
        pair_coeffs[23*COEFF_W +: COEFF_W] = -16'sd46;
        pair_coeffs[24*COEFF_W +: COEFF_W] = -16'sd26;
        pair_coeffs[25*COEFF_W +: COEFF_W] = 16'sd0;
        pair_coeffs[26*COEFF_W +: COEFF_W] = 16'sd31;
        pair_coeffs[27*COEFF_W +: COEFF_W] = 16'sd67;
        pair_coeffs[28*COEFF_W +: COEFF_W] = 16'sd109;
        pair_coeffs[29*COEFF_W +: COEFF_W] = 16'sd156;
        pair_coeffs[30*COEFF_W +: COEFF_W] = 16'sd208;
        pair_coeffs[31*COEFF_W +: COEFF_W] = 16'sd266;
        pair_coeffs[32*COEFF_W +: COEFF_W] = 16'sd327;
        pair_coeffs[33*COEFF_W +: COEFF_W] = 16'sd393;
        pair_coeffs[34*COEFF_W +: COEFF_W] = 16'sd462;
        pair_coeffs[35*COEFF_W +: COEFF_W] = 16'sd534;
        pair_coeffs[36*COEFF_W +: COEFF_W] = 16'sd607;
        pair_coeffs[37*COEFF_W +: COEFF_W] = 16'sd682;
        pair_coeffs[38*COEFF_W +: COEFF_W] = 16'sd756;
        pair_coeffs[39*COEFF_W +: COEFF_W] = 16'sd830;
        pair_coeffs[40*COEFF_W +: COEFF_W] = 16'sd901;
        pair_coeffs[41*COEFF_W +: COEFF_W] = 16'sd970;
        pair_coeffs[42*COEFF_W +: COEFF_W] = 16'sd1034;
        pair_coeffs[43*COEFF_W +: COEFF_W] = 16'sd1094;
        pair_coeffs[44*COEFF_W +: COEFF_W] = 16'sd1147;
        pair_coeffs[45*COEFF_W +: COEFF_W] = 16'sd1194;
        pair_coeffs[46*COEFF_W +: COEFF_W] = 16'sd1233;
        pair_coeffs[47*COEFF_W +: COEFF_W] = 16'sd1265;
        pair_coeffs[48*COEFF_W +: COEFF_W] = 16'sd1287;
        pair_coeffs[49*COEFF_W +: COEFF_W] = 16'sd1301;

        center_coeff = 16'sd1306;
    end

endmodule