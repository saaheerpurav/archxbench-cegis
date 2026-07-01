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

    localparam S_IDLE = 2'd0;
    localparam S_CALC = 2'd1;
    localparam S_DONE = 2'd2;

    reg [1:0] state;
    reg [LOGN-1:0] stage;
    reg [LOGN-1:0] bf_count;
    reg mode_reg;

    reg signed [OUT_W-1:0] mem_real [0:N-1];
    reg signed [OUT_W-1:0] mem_imag [0:N-1];

    wire [LOGN-1:0] idx_p;
    wire [LOGN-1:0] idx_q;
    wire [LOGN-1:0] tw_idx;

    wire signed [COEFF_W-1:0] tw_cos;
    wire signed [COEFF_W-1:0] tw_sin_pos;
    wire signed [COEFF_W-1:0] tw_sin_eff;

    wire signed [OUT_W-1:0] bf_a_real_out;
    wire signed [OUT_W-1:0] bf_a_imag_out;
    wire signed [OUT_W-1:0] bf_b_real_out;
    wire signed [OUT_W-1:0] bf_b_imag_out;

    wire signed [OUT_W-1:0] scaled_real [0:N-1];
    wire signed [OUT_W-1:0] scaled_imag [0:N-1];

    integer i;

    fft16_index_gen #(
        .N(N),
        .LOGN(LOGN)
    ) u_index_gen (
        .stage(stage),
        .bf_count(bf_count),
        .idx_p(idx_p),
        .idx_q(idx_q),
        .tw_idx(tw_idx)
    );

    fft16_twiddle_rom #(
        .COEFF_W(COEFF_W)
    ) u_twiddle_rom (
        .addr(tw_idx),
        .cos_q15(tw_cos),
        .sin_q15(tw_sin_pos)
    );

    fft16_twiddle_mode #(
        .COEFF_W(COEFF_W)
    ) u_twiddle_mode (
        .mode(mode_reg),
        .sin_q15_in(tw_sin_pos),
        .sin_q15_eff(tw_sin_eff)
    );

    fft16_butterfly #(
        .DATA_W(OUT_W),
        .COEFF_W(COEFF_W)
    ) u_butterfly (
        .a_real(mem_real[idx_p]),
        .a_imag(mem_imag[idx_p]),
        .b_real(mem_real[idx_q]),
        .b_imag(mem_imag[idx_q]),
        .tw_cos(tw_cos),
        .tw_sin(tw_sin_eff),
        .a_real_out(bf_a_real_out),
        .a_imag_out(bf_a_imag_out),
        .b_real_out(bf_b_real_out),
        .b_imag_out(bf_b_imag_out)
    );

    genvar g;
    generate
        for (g = 0; g < N; g = g + 1) begin : GEN_OUT_SCALE
            fft16_output_scale #(
                .OUT_W(OUT_W),
                .GAIN_W(GAIN_W)
            ) u_output_scale (
                .mode(mode_reg),
                .real_in(mem_real[g]),
                .imag_in(mem_imag[g]),
                .real_out(scaled_real[g]),
                .imag_out(scaled_imag[g])
            );

            assign data_real_out[g] = scaled_real[g];
            assign data_imag_out[g] = scaled_imag[g];
        end
    endgenerate

    assign done = (state == S_DONE);

    function [LOGN-1:0] bit_reverse4;
        input [LOGN-1:0] value;
        begin
            bit_reverse4 = {value[0], value[1], value[2], value[3]};
        end
    endfunction

    always @(posedge clk) begin
        if (rst) begin
            state    <= S_IDLE;
            stage    <= {LOGN{1'b0}};
            bf_count <= {LOGN{1'b0}};
            mode_reg <= 1'b0;
            for (i = 0; i < N; i = i + 1) begin
                mem_real[i] <= {OUT_W{1'b0}};
                mem_imag[i] <= {OUT_W{1'b0}};
            end
        end else begin
            case (state)
                S_IDLE: begin
                    if (start) begin
                        mode_reg <= mode;
                        stage    <= {LOGN{1'b0}};
                        bf_count <= {LOGN{1'b0}};
                        for (i = 0; i < N; i = i + 1) begin
                            mem_real[bit_reverse4(i[LOGN-1:0])] <= {{GAIN_W{data_real_in[i][DATA_W-1]}}, data_real_in[i]};
                            mem_imag[bit_reverse4(i[LOGN-1:0])] <= {{GAIN_W{data_imag_in[i][DATA_W-1]}}, data_imag_in[i]};
                        end
                        state <= S_CALC;
                    end
                end

                S_CALC: begin
                    mem_real[idx_p] <= bf_a_real_out;
                    mem_imag[idx_p] <= bf_a_imag_out;
                    mem_real[idx_q] <= bf_b_real_out;
                    mem_imag[idx_q] <= bf_b_imag_out;

                    if (bf_count == (N/2 - 1)) begin
                        bf_count <= {LOGN{1'b0}};
                        if (stage == (LOGN - 1)) begin
                            state <= S_DONE;
                        end else begin
                            stage <= stage + 1'b1;
                        end
                    end else begin
                        bf_count <= bf_count + 1'b1;
                    end
                end

                S_DONE: begin
                    if (start) begin
                        mode_reg <= mode;
                        stage    <= {LOGN{1'b0}};
                        bf_count <= {LOGN{1'b0}};
                        for (i = 0; i < N; i = i + 1) begin
                            mem_real[bit_reverse4(i[LOGN-1:0])] <= {{GAIN_W{data_real_in[i][DATA_W-1]}}, data_real_in[i]};
                            mem_imag[bit_reverse4(i[LOGN-1:0])] <= {{GAIN_W{data_imag_in[i][DATA_W-1]}}, data_imag_in[i]};
                        end
                        state <= S_CALC;
                    end
                end

                default: begin
                    state <= S_IDLE;
                end
            endcase
        end
    end

endmodule