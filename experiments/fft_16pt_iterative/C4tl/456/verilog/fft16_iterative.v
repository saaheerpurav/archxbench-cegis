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
    input mode, // 0: FFT, 1: IFFT
    input signed [DATA_W-1:0] data_real_in [0:N-1],
    input signed [DATA_W-1:0] data_imag_in [0:N-1],
    output signed [DATA_W+GAIN_W-1:0] data_real_out [0:N-1],
    output signed [DATA_W+GAIN_W-1:0] data_imag_out [0:N-1],
    output done
);

    localparam OUT_W  = DATA_W + GAIN_W;
    localparam IDX_W  = 4;
    localparam STAGES = 4;

    localparam S_IDLE = 2'd0;
    localparam S_RUN  = 2'd1;
    localparam S_DONE = 2'd2;

    reg [1:0] state;
    reg [1:0] stage;
    reg [3:0] butterfly;
    reg mode_r;
    reg done_r;

    reg signed [OUT_W-1:0] mem_real [0:N-1];
    reg signed [OUT_W-1:0] mem_imag [0:N-1];

    wire [IDX_W-1:0] p_idx;
    wire [IDX_W-1:0] q_idx;
    wire [IDX_W-1:0] tw_idx;

    wire signed [COEFF_W-1:0] tw_cos;
    wire signed [COEFF_W-1:0] tw_sin;

    wire signed [OUT_W-1:0] y0_real;
    wire signed [OUT_W-1:0] y0_imag;
    wire signed [OUT_W-1:0] y1_real;
    wire signed [OUT_W-1:0] y1_imag;

    genvar gi;
    generate
        for (gi = 0; gi < N; gi = gi + 1) begin : OUT_ASSIGN
            fft16_output_scale #(
                .IN_W(OUT_W),
                .GAIN_W(GAIN_W)
            ) out_scale_re (
                .din(mem_real[gi]),
                .mode(mode_r),
                .dout(data_real_out[gi])
            );

            fft16_output_scale #(
                .IN_W(OUT_W),
                .GAIN_W(GAIN_W)
            ) out_scale_im (
                .din(mem_imag[gi]),
                .mode(mode_r),
                .dout(data_imag_out[gi])
            );
        end
    endgenerate

    assign done = done_r;

    fft16_pair_index pair_index_u (
        .stage(stage),
        .butterfly(butterfly),
        .p_idx(p_idx),
        .q_idx(q_idx),
        .tw_idx(tw_idx)
    );

    fft16_twiddle_rom #(
        .COEFF_W(COEFF_W)
    ) twiddle_rom_u (
        .addr(tw_idx),
        .cos_q15(tw_cos),
        .sin_q15(tw_sin)
    );

    fft16_butterfly #(
        .DATA_W(OUT_W),
        .COEFF_W(COEFF_W)
    ) butterfly_u (
        .a_real(mem_real[p_idx]),
        .a_imag(mem_imag[p_idx]),
        .b_real(mem_real[q_idx]),
        .b_imag(mem_imag[q_idx]),
        .tw_cos(tw_cos),
        .tw_sin(tw_sin),
        .mode(mode_r),
        .y0_real(y0_real),
        .y0_imag(y0_imag),
        .y1_real(y1_real),
        .y1_imag(y1_imag)
    );

    integer i;
    integer br;

    always @(posedge clk) begin
        if (rst) begin
            state <= S_IDLE;
            stage <= 2'd0;
            butterfly <= 4'd0;
            mode_r <= 1'b0;
            done_r <= 1'b0;
            for (i = 0; i < N; i = i + 1) begin
                mem_real[i] <= {OUT_W{1'b0}};
                mem_imag[i] <= {OUT_W{1'b0}};
            end
        end else begin
            case (state)
                S_IDLE: begin
                    done_r <= 1'b0;
                    stage <= 2'd0;
                    butterfly <= 4'd0;

                    if (start) begin
                        mode_r <= mode;
                        for (i = 0; i < N; i = i + 1) begin
                            br = {i[0], i[1], i[2], i[3]};
                            mem_real[br] <= {{GAIN_W{data_real_in[i][DATA_W-1]}}, data_real_in[i]};
                            mem_imag[br] <= {{GAIN_W{data_imag_in[i][DATA_W-1]}}, data_imag_in[i]};
                        end
                        state <= S_RUN;
                    end
                end

                S_RUN: begin
                    mem_real[p_idx] <= y0_real;
                    mem_imag[p_idx] <= y0_imag;
                    mem_real[q_idx] <= y1_real;
                    mem_imag[q_idx] <= y1_imag;

                    if (butterfly == 4'd7) begin
                        butterfly <= 4'd0;
                        if (stage == 2'd3) begin
                            state <= S_DONE;
                            done_r <= 1'b1;
                        end else begin
                            stage <= stage + 2'd1;
                        end
                    end else begin
                        butterfly <= butterfly + 4'd1;
                    end
                end

                S_DONE: begin
                    done_r <= 1'b1;
                    if (start) begin
                        done_r <= 1'b0;
                        mode_r <= mode;
                        stage <= 2'd0;
                        butterfly <= 4'd0;
                        for (i = 0; i < N; i = i + 1) begin
                            br = {i[0], i[1], i[2], i[3]};
                            mem_real[br] <= {{GAIN_W{data_real_in[i][DATA_W-1]}}, data_real_in[i]};
                            mem_imag[br] <= {{GAIN_W{data_imag_in[i][DATA_W-1]}}, data_imag_in[i]};
                        end
                        state <= S_RUN;
                    end
                end

                default: begin
                    state <= S_IDLE;
                    done_r <= 1'b0;
                end
            endcase
        end
    end

endmodule