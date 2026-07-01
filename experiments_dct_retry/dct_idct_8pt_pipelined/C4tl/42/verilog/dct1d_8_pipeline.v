`timescale 1ns/1ps

module dct1d_8_pipeline #(
    parameter DATA_W = 12,
    parameter COEFF_W = 16,
    parameter OUT_W = 18
) (
    input clk,
    input rst,
    input [DATA_W-1:0] sample_in,
    input valid_in,
    input mode,
    input [2:0] index,
    output [OUT_W-1:0] coeff_out,
    output valid_out,
    output [2:0] index_out
);

    localparam ACC_W = DATA_W + COEFF_W + 4;

    reg signed [DATA_W-1:0] x0, x1, x2, x3, x4, x5, x6, x7;
    reg [3:0] in_count;
    reg block_mode;

    reg out_active;
    reg [2:0] out_sel;
    reg [OUT_W-1:0] coeff_out_r;
    reg valid_out_r;
    reg [2:0] index_out_r;

    wire signed [DATA_W-1:0] sample_s = sample_in;

    wire signed [COEFF_W-1:0] c00, c01, c02, c03, c04, c05, c06, c07;
    wire signed [COEFF_W-1:0] c10, c11, c12, c13, c14, c15, c16, c17;
    wire signed [COEFF_W-1:0] c20, c21, c22, c23, c24, c25, c26, c27;
    wire signed [COEFF_W-1:0] c30, c31, c32, c33, c34, c35, c36, c37;
    wire signed [COEFF_W-1:0] c40, c41, c42, c43, c44, c45, c46, c47;
    wire signed [COEFF_W-1:0] c50, c51, c52, c53, c54, c55, c56, c57;
    wire signed [COEFF_W-1:0] c60, c61, c62, c63, c64, c65, c66, c67;
    wire signed [COEFF_W-1:0] c70, c71, c72, c73, c74, c75, c76, c77;

    wire signed [ACC_W-1:0] acc0, acc1, acc2, acc3, acc4, acc5, acc6, acc7;
    wire signed [OUT_W-1:0] y0, y1, y2, y3, y4, y5, y6, y7;

    dct1d_8_coeff_rom #(.COEFF_W(COEFF_W)) rc00(.mode(block_mode), .out_index(3'd0), .in_index(3'd0), .coeff(c00));
    dct1d_8_coeff_rom #(.COEFF_W(COEFF_W)) rc01(.mode(block_mode), .out_index(3'd0), .in_index(3'd1), .coeff(c01));
    dct1d_8_coeff_rom #(.COEFF_W(COEFF_W)) rc02(.mode(block_mode), .out_index(3'd0), .in_index(3'd2), .coeff(c02));
    dct1d_8_coeff_rom #(.COEFF_W(COEFF_W)) rc03(.mode(block_mode), .out_index(3'd0), .in_index(3'd3), .coeff(c03));
    dct1d_8_coeff_rom #(.COEFF_W(COEFF_W)) rc04(.mode(block_mode), .out_index(3'd0), .in_index(3'd4), .coeff(c04));
    dct1d_8_coeff_rom #(.COEFF_W(COEFF_W)) rc05(.mode(block_mode), .out_index(3'd0), .in_index(3'd5), .coeff(c05));
    dct1d_8_coeff_rom #(.COEFF_W(COEFF_W)) rc06(.mode(block_mode), .out_index(3'd0), .in_index(3'd6), .coeff(c06));
    dct1d_8_coeff_rom #(.COEFF_W(COEFF_W)) rc07(.mode(block_mode), .out_index(3'd0), .in_index(3'd7), .coeff(c07));

    dct1d_8_coeff_rom #(.COEFF_W(COEFF_W)) rc10(.mode(block_mode), .out_index(3'd1), .in_index(3'd0), .coeff(c10));
    dct1d_8_coeff_rom #(.COEFF_W(COEFF_W)) rc11(.mode(block_mode), .out_index(3'd1), .in_index(3'd1), .coeff(c11));
    dct1d_8_coeff_rom #(.COEFF_W(COEFF_W)) rc12(.mode(block_mode), .out_index(3'd1), .in_index(3'd2), .coeff(c12));
    dct1d_8_coeff_rom #(.COEFF_W(COEFF_W)) rc13(.mode(block_mode), .out_index(3'd1), .in_index(3'd3), .coeff(c13));
    dct1d_8_coeff_rom #(.COEFF_W(COEFF_W)) rc14(.mode(block_mode), .out_index(3'd1), .in_index(3'd4), .coeff(c14));
    dct1d_8_coeff_rom #(.COEFF_W(COEFF_W)) rc15(.mode(block_mode), .out_index(3'd1), .in_index(3'd5), .coeff(c15));
    dct1d_8_coeff_rom #(.COEFF_W(COEFF_W)) rc16(.mode(block_mode), .out_index(3'd1), .in_index(3'd6), .coeff(c16));
    dct1d_8_coeff_rom #(.COEFF_W(COEFF_W)) rc17(.mode(block_mode), .out_index(3'd1), .in_index(3'd7), .coeff(c17));

    dct1d_8_coeff_rom #(.COEFF_W(COEFF_W)) rc20(.mode(block_mode), .out_index(3'd2), .in_index(3'd0), .coeff(c20));
    dct1d_8_coeff_rom #(.COEFF_W(COEFF_W)) rc21(.mode(block_mode), .out_index(3'd2), .in_index(3'd1), .coeff(c21));
    dct1d_8_coeff_rom #(.COEFF_W(COEFF_W)) rc22(.mode(block_mode), .out_index(3'd2), .in_index(3'd2), .coeff(c22));
    dct1d_8_coeff_rom #(.COEFF_W(COEFF_W)) rc23(.mode(block_mode), .out_index(3'd2), .in_index(3'd3), .coeff(c23));
    dct1d_8_coeff_rom #(.COEFF_W(COEFF_W)) rc24(.mode(block_mode), .out_index(3'd2), .in_index(3'd4), .coeff(c24));
    dct1d_8_coeff_rom #(.COEFF_W(COEFF_W)) rc25(.mode(block_mode), .out_index(3'd2), .in_index(3'd5), .coeff(c25));
    dct1d_8_coeff_rom #(.COEFF_W(COEFF_W)) rc26(.mode(block_mode), .out_index(3'd2), .in_index(3'd6), .coeff(c26));
    dct1d_8_coeff_rom #(.COEFF_W(COEFF_W)) rc27(.mode(block_mode), .out_index(3'd2), .in_index(3'd7), .coeff(c27));

    dct1d_8_coeff_rom #(.COEFF_W(COEFF_W)) rc30(.mode(block_mode), .out_index(3'd3), .in_index(3'd0), .coeff(c30));
    dct1d_8_coeff_rom #(.COEFF_W(COEFF_W)) rc31(.mode(block_mode), .out_index(3'd3), .in_index(3'd1), .coeff(c31));
    dct1d_8_coeff_rom #(.COEFF_W(COEFF_W)) rc32(.mode(block_mode), .out_index(3'd3), .in_index(3'd2), .coeff(c32));
    dct1d_8_coeff_rom #(.COEFF_W(COEFF_W)) rc33(.mode(block_mode), .out_index(3'd3), .in_index(3'd3), .coeff(c33));
    dct1d_8_coeff_rom #(.COEFF_W(COEFF_W)) rc34(.mode(block_mode), .out_index(3'd3), .in_index(3'd4), .coeff(c34));
    dct1d_8_coeff_rom #(.COEFF_W(COEFF_W)) rc35(.mode(block_mode), .out_index(3'd3), .in_index(3'd5), .coeff(c35));
    dct1d_8_coeff_rom #(.COEFF_W(COEFF_W)) rc36(.mode(block_mode), .out_index(3'd3), .in_index(3'd6), .coeff(c36));
    dct1d_8_coeff_rom #(.COEFF_W(COEFF_W)) rc37(.mode(block_mode), .out_index(3'd3), .in_index(3'd7), .coeff(c37));

    dct1d_8_coeff_rom #(.COEFF_W(COEFF_W)) rc40(.mode(block_mode), .out_index(3'd4), .in_index(3'd0), .coeff(c40));
    dct1d_8_coeff_rom #(.COEFF_W(COEFF_W)) rc41(.mode(block_mode), .out_index(3'd4), .in_index(3'd1), .coeff(c41));
    dct1d_8_coeff_rom #(.COEFF_W(COEFF_W)) rc42(.mode(block_mode), .out_index(3'd4), .in_index(3'd2), .coeff(c42));
    dct1d_8_coeff_rom #(.COEFF_W(COEFF_W)) rc43(.mode(block_mode), .out_index(3'd4), .in_index(3'd3), .coeff(c43));
    dct1d_8_coeff_rom #(.COEFF_W(COEFF_W)) rc44(.mode(block_mode), .out_index(3'd4), .in_index(3'd4), .coeff(c44));
    dct1d_8_coeff_rom #(.COEFF_W(COEFF_W)) rc45(.mode(block_mode), .out_index(3'd4), .in_index(3'd5), .coeff(c45));
    dct1d_8_coeff_rom #(.COEFF_W(COEFF_W)) rc46(.mode(block_mode), .out_index(3'd4), .in_index(3'd6), .coeff(c46));
    dct1d_8_coeff_rom #(.COEFF_W(COEFF_W)) rc47(.mode(block_mode), .out_index(3'd4), .in_index(3'd7), .coeff(c47));

    dct1d_8_coeff_rom #(.COEFF_W(COEFF_W)) rc50(.mode(block_mode), .out_index(3'd5), .in_index(3'd0), .coeff(c50));
    dct1d_8_coeff_rom #(.COEFF_W(COEFF_W)) rc51(.mode(block_mode), .out_index(3'd5), .in_index(3'd1), .coeff(c51));
    dct1d_8_coeff_rom #(.COEFF_W(COEFF_W)) rc52(.mode(block_mode), .out_index(3'd5), .in_index(3'd2), .coeff(c52));
    dct1d_8_coeff_rom #(.COEFF_W(COEFF_W)) rc53(.mode(block_mode), .out_index(3'd5), .in_index(3'd3), .coeff(c53));
    dct1d_8_coeff_rom #(.COEFF_W(COEFF_W)) rc54(.mode(block_mode), .out_index(3'd5), .in_index(3'd4), .coeff(c54));
    dct1d_8_coeff_rom #(.COEFF_W(COEFF_W)) rc55(.mode(block_mode), .out_index(3'd5), .in_index(3'd5), .coeff(c55));
    dct1d_8_coeff_rom #(.COEFF_W(COEFF_W)) rc56(.mode(block_mode), .out_index(3'd5), .in_index(3'd6), .coeff(c56));
    dct1d_8_coeff_rom #(.COEFF_W(COEFF_W)) rc57(.mode(block_mode), .out_index(3'd5), .in_index(3'd7), .coeff(c57));

    dct1d_8_coeff_rom #(.COEFF_W(COEFF_W)) rc60(.mode(block_mode), .out_index(3'd6), .in_index(3'd0), .coeff(c60));
    dct1d_8_coeff_rom #(.COEFF_W(COEFF_W)) rc61(.mode(block_mode), .out_index(3'd6), .in_index(3'd1), .coeff(c61));
    dct1d_8_coeff_rom #(.COEFF_W(COEFF_W)) rc62(.mode(block_mode), .out_index(3'd6), .in_index(3'd2), .coeff(c62));
    dct1d_8_coeff_rom #(.COEFF_W(COEFF_W)) rc63(.mode(block_mode), .out_index(3'd6), .in_index(3'd3), .coeff(c63));
    dct1d_8_coeff_rom #(.COEFF_W(COEFF_W)) rc64(.mode(block_mode), .out_index(3'd6), .in_index(3'd4), .coeff(c64));
    dct1d_8_coeff_rom #(.COEFF_W(COEFF_W)) rc65(.mode(block_mode), .out_index(3'd6), .in_index(3'd5), .coeff(c65));
    dct1d_8_coeff_rom #(.COEFF_W(COEFF_W)) rc66(.mode(block_mode), .out_index(3'd6), .in_index(3'd6), .coeff(c66));
    dct1d_8_coeff_rom #(.COEFF_W(COEFF_W)) rc67(.mode(block_mode), .out_index(3'd6), .in_index(3'd7), .coeff(c67));

    dct1d_8_coeff_rom #(.COEFF_W(COEFF_W)) rc70(.mode(block_mode), .out_index(3'd7), .in_index(3'd0), .coeff(c70));
    dct1d_8_coeff_rom #(.COEFF_W(COEFF_W)) rc71(.mode(block_mode), .out_index(3'd7), .in_index(3'd1), .coeff(c71));
    dct1d_8_coeff_rom #(.COEFF_W(COEFF_W)) rc72(.mode(block_mode), .out_index(3'd7), .in_index(3'd2), .coeff(c72));
    dct1d_8_coeff_rom #(.COEFF_W(COEFF_W)) rc73(.mode(block_mode), .out_index(3'd7), .in_index(3'd3), .coeff(c73));
    dct1d_8_coeff_rom #(.COEFF_W(COEFF_W)) rc74(.mode(block_mode), .out_index(3'd7), .in_index(3'd4), .coeff(c74));
    dct1d_8_coeff_rom #(.COEFF_W(COEFF_W)) rc75(.mode(block_mode), .out_index(3'd7), .in_index(3'd5), .coeff(c75));
    dct1d_8_coeff_rom #(.COEFF_W(COEFF_W)) rc76(.mode(block_mode), .out_index(3'd7), .in_index(3'd6), .coeff(c76));
    dct1d_8_coeff_rom #(.COEFF_W(COEFF_W)) rc77(.mode(block_mode), .out_index(3'd7), .in_index(3'd7), .coeff(c77));

    dct1d_8_mac #(.DATA_W(DATA_W), .COEFF_W(COEFF_W), .ACC_W(ACC_W)) m0(.x0(x0),.x1(x1),.x2(x2),.x3(x3),.x4(x4),.x5(x5),.x6(x6),.x7(x7),.c0(c00),.c1(c01),.c2(c02),.c3(c03),.c4(c04),.c5(c05),.c6(c06),.c7(c07),.acc(acc0));
    dct1d_8_mac #(.DATA_W(DATA_W), .COEFF_W(COEFF_W), .ACC_W(ACC_W)) m1(.x0(x0),.x1(x1),.x2(x2),.x3(x3),.x4(x4),.x5(x5),.x6(x6),.x7(x7),.c0(c10),.c1(c11),.c2(c12),.c3(c13),.c4(c14),.c5(c15),.c6(c16),.c7(c17),.acc(acc1));
    dct1d_8_mac #(.DATA_W(DATA_W), .COEFF_W(COEFF_W), .ACC_W(ACC_W)) m2(.x0(x0),.x1(x1),.x2(x2),.x3(x3),.x4(x4),.x5(x5),.x6(x6),.x7(x7),.c0(c20),.c1(c21),.c2(c22),.c3(c23),.c4(c24),.c5(c25),.c6(c26),.c7(c27),.acc(acc2));
    dct1d_8_mac #(.DATA_W(DATA_W), .COEFF_W(COEFF_W), .ACC_W(ACC_W)) m3(.x0(x0),.x1(x1),.x2(x2),.x3(x3),.x4(x4),.x5(x5),.x6(x6),.x7(x7),.c0(c30),.c1(c31),.c2(c32),.c3(c33),.c4(c34),.c5(c35),.c6(c36),.c7(c37),.acc(acc3));
    dct1d_8_mac #(.DATA_W(DATA_W), .COEFF_W(COEFF_W), .ACC_W(ACC_W)) m4(.x0(x0),.x1(x1),.x2(x2),.x3(x3),.x4(x4),.x5(x5),.x6(x6),.x7(x7),.c0(c40),.c1(c41),.c2(c42),.c3(c43),.c4(c44),.c5(c45),.c6(c46),.c7(c47),.acc(acc4));
    dct1d_8_mac #(.DATA_W(DATA_W), .COEFF_W(COEFF_W), .ACC_W(ACC_W)) m5(.x0(x0),.x1(x1),.x2(x2),.x3(x3),.x4(x4),.x5(x5),.x6(x6),.x7(x7),.c0(c50),.c1(c51),.c2(c52),.c3(c53),.c4(c54),.c5(c55),.c6(c56),.c7(c57),.acc(acc5));
    dct1d_8_mac #(.DATA_W(DATA_W), .COEFF_W(COEFF_W), .ACC_W(ACC_W)) m6(.x0(x0),.x1(x1),.x2(x2),.x3(x3),.x4(x4),.x5(x5),.x6(x6),.x7(x7),.c0(c60),.c1(c61),.c2(c62),.c3(c63),.c4(c64),.c5(c65),.c6(c66),.c7(c67),.acc(acc6));
    dct1d_8_mac #(.DATA_W(DATA_W), .COEFF_W(COEFF_W), .ACC_W(ACC_W)) m7(.x0(x0),.x1(x1),.x2(x2),.x3(x3),.x4(x4),.x5(x5),.x6(x6),.x7(x7),.c0(c70),.c1(c71),.c2(c72),.c3(c73),.c4(c74),.c5(c75),.c6(c76),.c7(c77),.acc(acc7));

    dct1d_8_round_saturate #(.IN_W(ACC_W), .OUT_W(OUT_W), .FRAC_W(14)) s0(.in_val(acc0), .out_val(y0));
    dct1d_8_round_saturate #(.IN_W(ACC_W), .OUT_W(OUT_W), .FRAC_W(14)) s1(.in_val(acc1), .out_val(y1));
    dct1d_8_round_saturate #(.IN_W(ACC_W), .OUT_W(OUT_W), .FRAC_W(14)) s2(.in_val(acc2), .out_val(y2));
    dct1d_8_round_saturate #(.IN_W(ACC_W), .OUT_W(OUT_W), .FRAC_W(14)) s3(.in_val(acc3), .out_val(y3));
    dct1d_8_round_saturate #(.IN_W(ACC_W), .OUT_W(OUT_W), .FRAC_W(14)) s4(.in_val(acc4), .out_val(y4));
    dct1d_8_round_saturate #(.IN_W(ACC_W), .OUT_W(OUT_W), .FRAC_W(14)) s5(.in_val(acc5), .out_val(y5));
    dct1d_8_round_saturate #(.IN_W(ACC_W), .OUT_W(OUT_W), .FRAC_W(14)) s6(.in_val(acc6), .out_val(y6));
    dct1d_8_round_saturate #(.IN_W(ACC_W), .OUT_W(OUT_W), .FRAC_W(14)) s7(.in_val(acc7), .out_val(y7));

    always @(posedge clk) begin
        if (rst) begin
            x0 <= 0; x1 <= 0; x2 <= 0; x3 <= 0;
            x4 <= 0; x5 <= 0; x6 <= 0; x7 <= 0;
            in_count <= 0;
            block_mode <= 0;
            out_active <= 0;
            out_sel <= 0;
            coeff_out_r <= 0;
            valid_out_r <= 0;
            index_out_r <= 0;
        end else begin
            valid_out_r <= 0;

            if (valid_in) begin
                if (in_count == 0)
                    block_mode <= mode;

                case (index)
                    3'd0: x0 <= sample_s;
                    3'd1: x1 <= sample_s;
                    3'd2: x2 <= sample_s;
                    3'd3: x3 <= sample_s;
                    3'd4: x4 <= sample_s;
                    3'd5: x5 <= sample_s;
                    3'd6: x6 <= sample_s;
                    default: x7 <= sample_s;
                endcase

                if (in_count == 4'd7) begin
                    in_count <= 0;
                    out_active <= 1;
                    out_sel <= 0;
                end else begin
                    in_count <= in_count + 1'b1;
                end
            end

            if (out_active) begin
                valid_out_r <= 1;
                index_out_r <= out_sel;
                case (out_sel)
                    3'd0: coeff_out_r <= y0;
                    3'd1: coeff_out_r <= y1;
                    3'd2: coeff_out_r <= y2;
                    3'd3: coeff_out_r <= y3;
                    3'd4: coeff_out_r <= y4;
                    3'd5: coeff_out_r <= y5;
                    3'd6: coeff_out_r <= y6;
                    default: coeff_out_r <= y7;
                endcase

                if (out_sel == 3'd7) begin
                    out_active <= 0;
                    out_sel <= 0;
                end else begin
                    out_sel <= out_sel + 1'b1;
                end
            end
        end
    end

    assign coeff_out = coeff_out_r;
    assign valid_out = valid_out_r;
    assign index_out = index_out_r;

endmodule