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
    output reg done
);

    localparam OUT_W = DATA_W + GAIN_W;
    localparam LOGN  = $clog2(N);

    localparam S_IDLE = 2'd0;
    localparam S_RUN  = 2'd1;
    localparam S_DONE = 2'd2;

    reg [1:0] state;

    reg [LOGN-1:0] stage;
    reg [LOGN-1:0] butterfly_count;

    reg signed [OUT_W-1:0] mem_real [0:N-1];
    reg signed [OUT_W-1:0] mem_imag [0:N-1];

    wire [LOGN-1:0] idx_p;
    wire [LOGN-1:0] idx_q;
    wire [LOGN-1:0] tw_idx;

    wire signed [COEFF_W-1:0] tw_cos;
    wire signed [COEFF_W-1:0] tw_sin;

    wire signed [OUT_W-1:0] bf_a_real_out;
    wire signed [OUT_W-1:0] bf_a_imag_out;
    wire signed [OUT_W-1:0] bf_b_real_out;
    wire signed [OUT_W-1:0] bf_b_imag_out;

    integer i;
    integer load_index;

    function integer bit_reverse_index;
        input integer idx;
        integer b;
        begin
            bit_reverse_index = 0;
            for (b = 0; b < LOGN; b = b + 1) begin
                if (idx & (1 << b))
                    bit_reverse_index = bit_reverse_index | (1 << (LOGN-1-b));
            end
        end
    endfunction

    fft16_index_gen #(
        .N(N)
    ) u_index_gen (
        .stage(stage),
        .butterfly_count(butterfly_count),
        .idx_p(idx_p),
        .idx_q(idx_q),
        .twiddle_idx(tw_idx)
    );

    fft16_twiddle_rom #(
        .N(N),
        .COEFF_W(COEFF_W)
    ) u_twiddle_rom (
        .twiddle_idx(tw_idx),
        .cos_q15(tw_cos),
        .sin_q15(tw_sin)
    );

    fft16_butterfly #(
        .DATA_W(DATA_W),
        .GAIN_W(GAIN_W),
        .COEFF_W(COEFF_W)
    ) u_butterfly (
        .mode(mode),
        .a_real(mem_real[idx_p]),
        .a_imag(mem_imag[idx_p]),
        .b_real(mem_real[idx_q]),
        .b_imag(mem_imag[idx_q]),
        .tw_cos(tw_cos),
        .tw_sin(tw_sin),
        .y0_real(bf_a_real_out),
        .y0_imag(bf_a_imag_out),
        .y1_real(bf_b_real_out),
        .y1_imag(bf_b_imag_out)
    );

    genvar g;
    generate
        for (g = 0; g < N; g = g + 1) begin : GEN_OUT_SCALE
            fft16_output_scale #(
                .N(N),
                .DATA_W(DATA_W),
                .GAIN_W(GAIN_W)
            ) u_scale_real (
                .mode(mode),
                .data_in(mem_real[g]),
                .data_out(data_real_out[g])
            );

            fft16_output_scale #(
                .N(N),
                .DATA_W(DATA_W),
                .GAIN_W(GAIN_W)
            ) u_scale_imag (
                .mode(mode),
                .data_in(mem_imag[g]),
                .data_out(data_imag_out[g])
            );
        end
    endgenerate

    always @(posedge clk) begin
        if (rst) begin
            state            <= S_IDLE;
            done             <= 1'b0;
            stage            <= {LOGN{1'b0}};
            butterfly_count  <= {LOGN{1'b0}};

            for (i = 0; i < N; i = i + 1) begin
                mem_real[i] <= {OUT_W{1'b0}};
                mem_imag[i] <= {OUT_W{1'b0}};
            end
        end else begin
            case (state)
                S_IDLE: begin
                    done <= 1'b0;

                    if (start) begin
                        for (i = 0; i < N; i = i + 1) begin
                            load_index = bit_reverse_index(i);
                            mem_real[load_index] <= {{GAIN_W{data_real_in[i][DATA_W-1]}}, data_real_in[i]};
                            mem_imag[load_index] <= {{GAIN_W{data_imag_in[i][DATA_W-1]}}, data_imag_in[i]};
                        end

                        stage           <= {LOGN{1'b0}};
                        butterfly_count <= {LOGN{1'b0}};
                        state           <= S_RUN;
                    end
                end

                S_RUN: begin
                    done <= 1'b0;

                    mem_real[idx_p] <= bf_a_real_out;
                    mem_imag[idx_p] <= bf_a_imag_out;
                    mem_real[idx_q] <= bf_b_real_out;
                    mem_imag[idx_q] <= bf_b_imag_out;

                    if ((stage == LOGN-1) && (butterfly_count == (N/2)-1)) begin
                        state <= S_DONE;
                        done  <= 1'b1;
                    end else if (butterfly_count == (N/2)-1) begin
                        butterfly_count <= {LOGN{1'b0}};
                        stage           <= stage + {{(LOGN-1){1'b0}}, 1'b1};
                    end else begin
                        butterfly_count <= butterfly_count + {{(LOGN-1){1'b0}}, 1'b1};
                    end
                end

                S_DONE: begin
                    done <= 1'b1;

                    if (start) begin
                        done <= 1'b0;

                        for (i = 0; i < N; i = i + 1) begin
                            load_index = bit_reverse_index(i);
                            mem_real[load_index] <= {{GAIN_W{data_real_in[i][DATA_W-1]}}, data_real_in[i]};
                            mem_imag[load_index] <= {{GAIN_W{data_imag_in[i][DATA_W-1]}}, data_imag_in[i]};
                        end

                        stage           <= {LOGN{1'b0}};
                        butterfly_count <= {LOGN{1'b0}};
                        state           <= S_RUN;
                    end
                end

                default: begin
                    state <= S_IDLE;
                    done  <= 1'b0;
                end
            endcase
        end
    end

endmodule