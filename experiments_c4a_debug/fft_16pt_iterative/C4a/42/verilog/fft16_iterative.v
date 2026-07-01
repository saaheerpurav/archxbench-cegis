`timescale 1ns/1ps

module fft16_iterative #(
    parameter N = 16,
    parameter DATA_W = 12,
    parameter COEFF_W = 16,
    parameter GAIN_W = 4
) (
    input clk,
    input rst,
    input start,
    input mode,
    input signed [DATA_W-1:0] data_real_in [0:N-1],
    input signed [DATA_W-1:0] data_imag_in [0:N-1],
    output signed [DATA_W+GAIN_W-1:0] data_real_out [0:N-1],
    output signed [DATA_W+GAIN_W-1:0] data_imag_out [0:N-1],
    output done
);

    localparam OUT_W = DATA_W + GAIN_W;
    localparam LOGN  = 4;

    reg signed [OUT_W-1:0] out_re [0:N-1];
    reg signed [OUT_W-1:0] out_im [0:N-1];
    reg done_reg;

    integer i;
    integer k;
    integer n;
    integer idx;

    reg signed [31:0] acc_re;
    reg signed [31:0] acc_im;
    reg signed [31:0] prod_re;
    reg signed [31:0] prod_im;
    reg signed [31:0] xr;
    reg signed [31:0] xi;
    reg signed [COEFF_W-1:0] c;
    reg signed [COEFF_W-1:0] s;

    assign done = done_reg;

    genvar gi;
    generate
        for (gi = 0; gi < N; gi = gi + 1) begin : OUT_ASSIGN
            assign data_real_out[gi] = out_re[gi];
            assign data_imag_out[gi] = out_im[gi];
        end
    endgenerate

    function signed [COEFF_W-1:0] cos_q15;
        input [3:0] a;
        begin
            case (a)
                4'd0:  cos_q15 = 16'sd32767;
                4'd1:  cos_q15 = 16'sd30274;
                4'd2:  cos_q15 = 16'sd23170;
                4'd3:  cos_q15 = 16'sd12540;
                4'd4:  cos_q15 = 16'sd0;
                4'd5:  cos_q15 = -16'sd12540;
                4'd6:  cos_q15 = -16'sd23170;
                4'd7:  cos_q15 = -16'sd30274;
                4'd8:  cos_q15 = -16'sd32768;
                4'd9:  cos_q15 = -16'sd30274;
                4'd10: cos_q15 = -16'sd23170;
                4'd11: cos_q15 = -16'sd12540;
                4'd12: cos_q15 = 16'sd0;
                4'd13: cos_q15 = 16'sd12540;
                4'd14: cos_q15 = 16'sd23170;
                4'd15: cos_q15 = 16'sd30274;
            endcase
        end
    endfunction

    function signed [COEFF_W-1:0] sin_q15;
        input [3:0] a;
        begin
            case (a)
                4'd0:  sin_q15 = 16'sd0;
                4'd1:  sin_q15 = 16'sd12540;
                4'd2:  sin_q15 = 16'sd23170;
                4'd3:  sin_q15 = 16'sd30274;
                4'd4:  sin_q15 = 16'sd32767;
                4'd5:  sin_q15 = 16'sd30274;
                4'd6:  sin_q15 = 16'sd23170;
                4'd7:  sin_q15 = 16'sd12540;
                4'd8:  sin_q15 = 16'sd0;
                4'd9:  sin_q15 = -16'sd12540;
                4'd10: sin_q15 = -16'sd23170;
                4'd11: sin_q15 = -16'sd30274;
                4'd12: sin_q15 = -16'sd32768;
                4'd13: sin_q15 = -16'sd30274;
                4'd14: sin_q15 = -16'sd23170;
                4'd15: sin_q15 = -16'sd12540;
            endcase
        end
    endfunction

    always @(posedge clk) begin
        if (rst) begin
            done_reg <= 1'b0;
            for (i = 0; i < N; i = i + 1) begin
                out_re[i] <= {OUT_W{1'b0}};
                out_im[i] <= {OUT_W{1'b0}};
            end
        end else begin
            done_reg <= 1'b0;

            if (start) begin
                for (k = 0; k < N; k = k + 1) begin
                    acc_re = 32'sd0;
                    acc_im = 32'sd0;

                    for (n = 0; n < N; n = n + 1) begin
                        idx = (k * n) & 15;
                        c = cos_q15(idx[3:0]);
                        s = sin_q15(idx[3:0]);

                        xr = {{(32-DATA_W){data_real_in[n][DATA_W-1]}}, data_real_in[n]};
                        xi = {{(32-DATA_W){data_imag_in[n][DATA_W-1]}}, data_imag_in[n]};

                        if (mode) begin
                            prod_re = ((xr * c) - (xi * s) + 32'sd16384) >>> 15;
                            prod_im = ((xi * c) + (xr * s) + 32'sd16384) >>> 15;
                        end else begin
                            prod_re = ((xr * c) + (xi * s) + 32'sd16384) >>> 15;
                            prod_im = ((xi * c) - (xr * s) + 32'sd16384) >>> 15;
                        end

                        acc_re = acc_re + prod_re;
                        acc_im = acc_im + prod_im;
                    end

                    if (mode) begin
                        out_re[k] <= acc_re >>> LOGN;
                        out_im[k] <= acc_im >>> LOGN;
                    end else begin
                        out_re[k] <= acc_re[OUT_W-1:0];
                        out_im[k] <= acc_im[OUT_W-1:0];
                    end
                end

                done_reg <= 1'b1;
            end
        end
    end

endmodule