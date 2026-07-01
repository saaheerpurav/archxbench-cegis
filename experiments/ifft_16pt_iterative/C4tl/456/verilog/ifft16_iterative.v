`timescale 1ns/1ps

module ifft16_iterative #(
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
    localparam STAGES = 4;
    localparam BF_PER_STAGE = N/2;

    localparam S_IDLE  = 3'd0;
    localparam S_LOAD  = 3'd1;
    localparam S_CALC  = 3'd2;
    localparam S_SCALE = 3'd3;
    localparam S_DONE  = 3'd4;

    reg [2:0] state;
    reg [2:0] stage;
    reg [3:0] butterfly_idx;
    reg done_r;

    reg signed [OUT_W-1:0] mem_real [0:N-1];
    reg signed [OUT_W-1:0] mem_imag [0:N-1];
    reg signed [OUT_W-1:0] out_real_r [0:N-1];
    reg signed [OUT_W-1:0] out_imag_r [0:N-1];

    wire [3:0] br_addr [0:N-1];

    genvar gi;
    generate
        for (gi = 0; gi < N; gi = gi + 1) begin : GEN_ADDR
            fft16_bit_reverse_addr u_bit_reverse_addr (
                .addr_in (gi[3:0]),
                .addr_out(br_addr[gi])
            );

            assign data_real_out[gi] = out_real_r[gi];
            assign data_imag_out[gi] = out_imag_r[gi];
        end
    endgenerate

    assign done = done_r;

    wire [3:0] p_idx;
    wire [3:0] q_idx;
    wire [3:0] tw_idx;

    fft16_pair_index u_pair_index (
        .stage        (stage[1:0]),
        .butterfly_idx(butterfly_idx),
        .p_idx        (p_idx),
        .q_idx        (q_idx),
        .tw_idx       (tw_idx)
    );

    wire signed [COEFF_W-1:0] tw_cos;
    wire signed [COEFF_W-1:0] tw_sin;

    fft16_twiddle_rom #(
        .COEFF_W(COEFF_W)
    ) u_twiddle_rom (
        .tw_idx(tw_idx),
        .cos_q15(tw_cos),
        .sin_q15(tw_sin)
    );

    wire signed [OUT_W-1:0] bf_p_real;
    wire signed [OUT_W-1:0] bf_p_imag;
    wire signed [OUT_W-1:0] bf_q_real;
    wire signed [OUT_W-1:0] bf_q_imag;

    fft16_ifft_butterfly #(
        .DATA_W (OUT_W),
        .COEFF_W(COEFF_W)
    ) u_butterfly (
        .a_real (mem_real[p_idx]),
        .a_imag (mem_imag[p_idx]),
        .b_real (mem_real[q_idx]),
        .b_imag (mem_imag[q_idx]),
        .tw_cos (tw_cos),
        .tw_sin (tw_sin),
        .y0_real(bf_p_real),
        .y0_imag(bf_p_imag),
        .y1_real(bf_q_real),
        .y1_imag(bf_q_imag)
    );

    wire signed [OUT_W-1:0] scaled_real [0:N-1];
    wire signed [OUT_W-1:0] scaled_imag [0:N-1];

    generate
        for (gi = 0; gi < N; gi = gi + 1) begin : GEN_SCALE
            fft16_ifft_output_scale #(
                .DATA_W(OUT_W),
                .SHIFT (GAIN_W)
            ) u_output_scale (
                .in_real (mem_real[gi]),
                .in_imag (mem_imag[gi]),
                .out_real(scaled_real[gi]),
                .out_imag(scaled_imag[gi])
            );
        end
    endgenerate

    integer i;

    always @(posedge clk) begin
        if (rst) begin
            state <= S_IDLE;
            stage <= 3'd0;
            butterfly_idx <= 4'd0;
            done_r <= 1'b0;
            for (i = 0; i < N; i = i + 1) begin
                mem_real[i] <= {OUT_W{1'b0}};
                mem_imag[i] <= {OUT_W{1'b0}};
                out_real_r[i] <= {OUT_W{1'b0}};
                out_imag_r[i] <= {OUT_W{1'b0}};
            end
        end else begin
            case (state)
                S_IDLE: begin
                    done_r <= 1'b0;
                    stage <= 3'd0;
                    butterfly_idx <= 4'd0;
                    if (start) begin
                        state <= S_LOAD;
                    end
                end

                S_LOAD: begin
                    done_r <= 1'b0;
                    for (i = 0; i < N; i = i + 1) begin
                        mem_real[br_addr[i]] <= {{GAIN_W{data_real_in[i][DATA_W-1]}}, data_real_in[i]};
                        mem_imag[br_addr[i]] <= {{GAIN_W{data_imag_in[i][DATA_W-1]}}, data_imag_in[i]};
                    end
                    stage <= 3'd0;
                    butterfly_idx <= 4'd0;
                    state <= S_CALC;
                end

                S_CALC: begin
                    mem_real[p_idx] <= bf_p_real;
                    mem_imag[p_idx] <= bf_p_imag;
                    mem_real[q_idx] <= bf_q_real;
                    mem_imag[q_idx] <= bf_q_imag;

                    if (butterfly_idx == BF_PER_STAGE-1) begin
                        butterfly_idx <= 4'd0;
                        if (stage == STAGES-1) begin
                            state <= S_SCALE;
                        end else begin
                            stage <= stage + 3'd1;
                        end
                    end else begin
                        butterfly_idx <= butterfly_idx + 4'd1;
                    end
                end

                S_SCALE: begin
                    for (i = 0; i < N; i = i + 1) begin
                        out_real_r[i] <= scaled_real[i];
                        out_imag_r[i] <= scaled_imag[i];
                    end
                    done_r <= 1'b1;
                    state <= S_DONE;
                end

                S_DONE: begin
                    done_r <= 1'b1;
                    if (start) begin
                        done_r <= 1'b0;
                        state <= S_LOAD;
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