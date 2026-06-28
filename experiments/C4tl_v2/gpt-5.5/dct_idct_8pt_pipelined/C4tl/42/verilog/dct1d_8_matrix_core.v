`timescale 1ns/1ps

module dct1d_8_matrix_core #(
    parameter DATA_W  = 12,
    parameter COEFF_W = 16,
    parameter OUT_W   = 18
) (
    input mode, // 0 = DCT, 1 = IDCT

    input signed [DATA_W-1:0] x0,
    input signed [DATA_W-1:0] x1,
    input signed [DATA_W-1:0] x2,
    input signed [DATA_W-1:0] x3,
    input signed [DATA_W-1:0] x4,
    input signed [DATA_W-1:0] x5,
    input signed [DATA_W-1:0] x6,
    input signed [DATA_W-1:0] x7,

    output signed [OUT_W-1:0] y0,
    output signed [OUT_W-1:0] y1,
    output signed [OUT_W-1:0] y2,
    output signed [OUT_W-1:0] y3,
    output signed [OUT_W-1:0] y4,
    output signed [OUT_W-1:0] y5,
    output signed [OUT_W-1:0] y6,
    output signed [OUT_W-1:0] y7
);

    localparam integer FRAC_BITS = 14;
    localparam integer SUM_W     = DATA_W + COEFF_W + 4;

    /*
     * Q2.14 orthonormal 8-point DCT-II coefficient matrix.
     *
     * Row 0 coefficient:
     *   1 / sqrt(8) ~= 0.3535533906
     *   round(0.3535533906 * 2^14) = 5793
     *
     * Rows 1..7:
     *   alpha = sqrt(2/8) = 0.5
     *   coefficient = 0.5 * cos(pi/8 * (n + 0.5) * k)
     *
     * DCT:
     *   y[k] = sum_n C[k][n] x[n]
     *
     * IDCT:
     *   y[n] = sum_k C[k][n] x[k] = C^T x
     */
    function signed [COEFF_W-1:0] dct_c;
        input [2:0] row;
        input [2:0] col;
        begin
            case (row)
                3'd0: begin
                    case (col)
                        3'd0: dct_c = 16'sd5793;
                        3'd1: dct_c = 16'sd5793;
                        3'd2: dct_c = 16'sd5793;
                        3'd3: dct_c = 16'sd5793;
                        3'd4: dct_c = 16'sd5793;
                        3'd5: dct_c = 16'sd5793;
                        3'd6: dct_c = 16'sd5793;
                        3'd7: dct_c = 16'sd5793;
                        default: dct_c = {COEFF_W{1'b0}};
                    endcase
                end

                3'd1: begin
                    case (col)
                        3'd0: dct_c = 16'sd8035;
                        3'd1: dct_c = 16'sd6811;
                        3'd2: dct_c = 16'sd4551;
                        3'd3: dct_c = 16'sd1598;
                        3'd4: dct_c = -16'sd1598;
                        3'd5: dct_c = -16'sd4551;
                        3'd6: dct_c = -16'sd6811;
                        3'd7: dct_c = -16'sd8035;
                        default: dct_c = {COEFF_W{1'b0}};
                    endcase
                end

                3'd2: begin
                    case (col)
                        3'd0: dct_c = 16'sd7568;
                        3'd1: dct_c = 16'sd3135;
                        3'd2: dct_c = -16'sd3135;
                        3'd3: dct_c = -16'sd7568;
                        3'd4: dct_c = -16'sd7568;
                        3'd5: dct_c = -16'sd3135;
                        3'd6: dct_c = 16'sd3135;
                        3'd7: dct_c = 16'sd7568;
                        default: dct_c = {COEFF_W{1'b0}};
                    endcase
                end

                3'd3: begin
                    case (col)
                        3'd0: dct_c = 16'sd6811;
                        3'd1: dct_c = -16'sd1598;
                        3'd2: dct_c = -16'sd8035;
                        3'd3: dct_c = -16'sd4551;
                        3'd4: dct_c = 16'sd4551;
                        3'd5: dct_c = 16'sd8035;
                        3'd6: dct_c = 16'sd1598;
                        3'd7: dct_c = -16'sd6811;
                        default: dct_c = {COEFF_W{1'b0}};
                    endcase
                end

                3'd4: begin
                    case (col)
                        3'd0: dct_c = 16'sd5793;
                        3'd1: dct_c = -16'sd5793;
                        3'd2: dct_c = -16'sd5793;
                        3'd3: dct_c = 16'sd5793;
                        3'd4: dct_c = 16'sd5793;
                        3'd5: dct_c = -16'sd5793;
                        3'd6: dct_c = -16'sd5793;
                        3'd7: dct_c = 16'sd5793;
                        default: dct_c = {COEFF_W{1'b0}};
                    endcase
                end

                3'd5: begin
                    case (col)
                        3'd0: dct_c = 16'sd4551;
                        3'd1: dct_c = -16'sd8035;
                        3'd2: dct_c = 16'sd1598;
                        3'd3: dct_c = 16'sd6811;
                        3'd4: dct_c = -16'sd6811;
                        3'd5: dct_c = -16'sd1598;
                        3'd6: dct_c = 16'sd8035;
                        3'd7: dct_c = -16'sd4551;
                        default: dct_c = {COEFF_W{1'b0}};
                    endcase
                end

                3'd6: begin
                    case (col)
                        3'd0: dct_c = 16'sd3135;
                        3'd1: dct_c = -16'sd7568;
                        3'd2: dct_c = 16'sd7568;
                        3'd3: dct_c = -16'sd3135;
                        3'd4: dct_c = -16'sd3135;
                        3'd5: dct_c = 16'sd7568;
                        3'd6: dct_c = -16'sd7568;
                        3'd7: dct_c = 16'sd3135;
                        default: dct_c = {COEFF_W{1'b0}};
                    endcase
                end

                3'd7: begin
                    case (col)
                        3'd0: dct_c = 16'sd1598;
                        3'd1: dct_c = -16'sd4551;
                        3'd2: dct_c = 16'sd6811;
                        3'd3: dct_c = -16'sd8035;
                        3'd4: dct_c = 16'sd8035;
                        3'd5: dct_c = -16'sd6811;
                        3'd6: dct_c = 16'sd4551;
                        3'd7: dct_c = -16'sd1598;
                        default: dct_c = {COEFF_W{1'b0}};
                    endcase
                end

                default: begin
                    dct_c = {COEFF_W{1'b0}};
                end
            endcase
        end
    endfunction

    function signed [COEFF_W-1:0] coeff_sel;
        input       mode_i;
        input [2:0] out_i;
        input [2:0] in_i;
        begin
            if (mode_i) begin
                /*
                 * IDCT uses the transpose of the orthonormal DCT matrix.
                 */
                coeff_sel = dct_c(in_i, out_i);
            end else begin
                /*
                 * DCT uses the matrix directly.
                 */
                coeff_sel = dct_c(out_i, in_i);
            end
        end
    endfunction

    function signed [SUM_W-1:0] dot8;
        input [2:0] row;

        reg signed [SUM_W-1:0] acc;
        reg signed [SUM_W-1:0] p0;
        reg signed [SUM_W-1:0] p1;
        reg signed [SUM_W-1:0] p2;
        reg signed [SUM_W-1:0] p3;
        reg signed [SUM_W-1:0] p4;
        reg signed [SUM_W-1:0] p5;
        reg signed [SUM_W-1:0] p6;
        reg signed [SUM_W-1:0] p7;

        begin
            p0 = x0 * coeff_sel(mode, row, 3'd0);
            p1 = x1 * coeff_sel(mode, row, 3'd1);
            p2 = x2 * coeff_sel(mode, row, 3'd2);
            p3 = x3 * coeff_sel(mode, row, 3'd3);
            p4 = x4 * coeff_sel(mode, row, 3'd4);
            p5 = x5 * coeff_sel(mode, row, 3'd5);
            p6 = x6 * coeff_sel(mode, row, 3'd6);
            p7 = x7 * coeff_sel(mode, row, 3'd7);

            acc = p0 + p1 + p2 + p3 + p4 + p5 + p6 + p7;

            dot8 = acc;
        end
    endfunction

    function signed [OUT_W-1:0] shift_and_saturate;
        input signed [SUM_W-1:0] acc_in;

        reg signed [SUM_W-1:0] shifted;
        reg signed [SUM_W-1:0] max_ext;
        reg signed [SUM_W-1:0] min_ext;

        begin
            /*
             * Remove Q2.14 coefficient fractional scaling.
             * Arithmetic shift preserves the sign for negative sums.
             */
            shifted = acc_in >>> FRAC_BITS;

            /*
             * Signed OUT_W limits, sign-extended to SUM_W for comparison.
             *
             * max =  2^(OUT_W-1) - 1
             * min = -2^(OUT_W-1)
             */
            max_ext = {{(SUM_W-OUT_W){1'b0}}, {1'b0, {(OUT_W-1){1'b1}}}};
            min_ext = {{(SUM_W-OUT_W){1'b1}}, {1'b1, {(OUT_W-1){1'b0}}}};

            if (shifted > max_ext) begin
                shift_and_saturate = {1'b0, {(OUT_W-1){1'b1}}};
            end else if (shifted < min_ext) begin
                shift_and_saturate = {1'b1, {(OUT_W-1){1'b0}}};
            end else begin
                shift_and_saturate = shifted[OUT_W-1:0];
            end
        end
    endfunction

    assign y0 = shift_and_saturate(dot8(3'd0));
    assign y1 = shift_and_saturate(dot8(3'd1));
    assign y2 = shift_and_saturate(dot8(3'd2));
    assign y3 = shift_and_saturate(dot8(3'd3));
    assign y4 = shift_and_saturate(dot8(3'd4));
    assign y5 = shift_and_saturate(dot8(3'd5));
    assign y6 = shift_and_saturate(dot8(3'd6));
    assign y7 = shift_and_saturate(dot8(3'd7));

endmodule