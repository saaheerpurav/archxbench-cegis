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
    output reg signed [DATA_W+GAIN_W-1:0] data_real_out [0:N-1],
    output reg signed [DATA_W+GAIN_W-1:0] data_imag_out [0:N-1],
    output reg done
);

    localparam OUT_W   = DATA_W + GAIN_W;
    localparam IDX_W   = (N <= 2) ? 1 : $clog2(N);
    localparam STAGES  = $clog2(N);
    localparam STAGE_W = (STAGES <= 1) ? 1 : $clog2(STAGES);

    localparam [1:0] S_IDLE    = 2'd0;
    localparam [1:0] S_COMPUTE = 2'd1;
    localparam [1:0] S_SCALE   = 2'd2;
    localparam [1:0] S_DONE    = 2'd3;

    reg [1:0] state;

    reg [STAGE_W-1:0] stage_cnt;
    reg [IDX_W-1:0]   j_cnt;
    reg [IDX_W-1:0]   group_cnt;

    reg mode_reg;

    reg signed [OUT_W-1:0] mem_re [0:N-1];
    reg signed [OUT_W-1:0] mem_im [0:N-1];

    wire [IDX_W-1:0] load_idx   [0:N-1];
    wire [IDX_W-1:0] bitrev_idx [0:N-1];

    genvar gi;
    generate
        for (gi = 0; gi < N; gi = gi + 1) begin : GEN_BITREV
            assign load_idx[gi] = gi[IDX_W-1:0];

            ifft16_bit_reverse #(
                .WIDTH(IDX_W)
            ) u_bit_reverse (
                .idx(load_idx[gi]),
                .rev(bitrev_idx[gi])
            );
        end
    endgenerate

    wire [IDX_W-1:0] p_idx;
    wire [IDX_W-1:0] q_idx;
    wire [IDX_W-1:0] tw_idx;
    wire             last_group;
    wire             last_stage;
    wire             last_all;

    ifft16_pair_index #(
        .N(N),
        .IDX_W(IDX_W),
        .STAGE_W(STAGE_W)
    ) u_pair_index (
        .stage(stage_cnt),
        .j(j_cnt),
        .group(group_cnt),
        .p_idx(p_idx),
        .q_idx(q_idx),
        .tw_idx(tw_idx),
        .last_group(last_group),
        .last_stage(last_stage),
        .last_all(last_all)
    );

    wire signed [COEFF_W-1:0] tw_cos;
    wire signed [COEFF_W-1:0] tw_sin_pos;
    wire signed [COEFF_W-1:0] tw_sin_eff;

    ifft16_twiddle_rom #(
        .N(N),
        .COEFF_W(COEFF_W),
        .IDX_W(IDX_W)
    ) u_twiddle_rom (
        .idx(tw_idx),
        .cos_q15(tw_cos),
        .sin_q15(tw_sin_pos)
    );

    assign tw_sin_eff = mode_reg ? tw_sin_pos : -tw_sin_pos;

    wire signed [OUT_W-1:0] bf_p_re;
    wire signed [OUT_W-1:0] bf_p_im;
    wire signed [OUT_W-1:0] bf_q_re;
    wire signed [OUT_W-1:0] bf_q_im;

    ifft16_butterfly_q15 #(
        .IN_W(OUT_W),
        .COEFF_W(COEFF_W)
    ) u_butterfly (
        .a_re(mem_re[p_idx]),
        .a_im(mem_im[p_idx]),
        .b_re(mem_re[q_idx]),
        .b_im(mem_im[q_idx]),
        .w_re(tw_cos),
        .w_im(tw_sin_eff),
        .y0_re(bf_p_re),
        .y0_im(bf_p_im),
        .y1_re(bf_q_re),
        .y1_im(bf_q_im)
    );

    wire signed [OUT_W-1:0] scaled_re [0:N-1];
    wire signed [OUT_W-1:0] scaled_im [0:N-1];

    generate
        for (gi = 0; gi < N; gi = gi + 1) begin : GEN_SCALE
            ifft16_output_scale #(
                .IN_W(OUT_W),
                .OUT_W(OUT_W),
                .SHIFT(GAIN_W)
            ) u_scale_re (
                .mode_ifft(mode_reg),
                .in_val(mem_re[gi]),
                .out_val(scaled_re[gi])
            );

            ifft16_output_scale #(
                .IN_W(OUT_W),
                .OUT_W(OUT_W),
                .SHIFT(GAIN_W)
            ) u_scale_im (
                .mode_ifft(mode_reg),
                .in_val(mem_im[gi]),
                .out_val(scaled_im[gi])
            );
        end
    endgenerate

    integer ii;

    always @(posedge clk) begin
        if (rst) begin
            state     <= S_IDLE;
            done      <= 1'b0;
            stage_cnt <= {STAGE_W{1'b0}};
            j_cnt     <= {IDX_W{1'b0}};
            group_cnt <= {IDX_W{1'b0}};
            mode_reg  <= 1'b1;

            for (ii = 0; ii < N; ii = ii + 1) begin
                mem_re[ii]       <= {OUT_W{1'b0}};
                mem_im[ii]       <= {OUT_W{1'b0}};
                data_real_out[ii] <= {OUT_W{1'b0}};
                data_imag_out[ii] <= {OUT_W{1'b0}};
            end
        end else begin
            case (state)
                S_IDLE: begin
                    done <= 1'b0;

                    if (start) begin
                        mode_reg  <= mode;
                        stage_cnt <= {STAGE_W{1'b0}};
                        j_cnt     <= {IDX_W{1'b0}};
                        group_cnt <= {IDX_W{1'b0}};

                        for (ii = 0; ii < N; ii = ii + 1) begin
                            mem_re[ii] <= {{GAIN_W{data_real_in[bitrev_idx[ii]][DATA_W-1]}},
                                           data_real_in[bitrev_idx[ii]]};
                            mem_im[ii] <= {{GAIN_W{data_imag_in[bitrev_idx[ii]][DATA_W-1]}},
                                           data_imag_in[bitrev_idx[ii]]};
                        end

                        state <= S_COMPUTE;
                    end
                end

                S_COMPUTE: begin
                    done <= 1'b0;

                    mem_re[p_idx] <= bf_p_re;
                    mem_im[p_idx] <= bf_p_im;
                    mem_re[q_idx] <= bf_q_re;
                    mem_im[q_idx] <= bf_q_im;

                    if (last_all) begin
                        state <= S_SCALE;
                    end else if (last_stage) begin
                        stage_cnt <= stage_cnt + {{(STAGE_W-1){1'b0}}, 1'b1};
                        j_cnt     <= {IDX_W{1'b0}};
                        group_cnt <= {IDX_W{1'b0}};
                    end else if (last_group) begin
                        group_cnt <= {IDX_W{1'b0}};
                        j_cnt     <= j_cnt + {{(IDX_W-1){1'b0}}, 1'b1};
                    end else begin
                        group_cnt <= group_cnt + {{(IDX_W-1){1'b0}}, 1'b1};
                    end
                end

                S_SCALE: begin
                    for (ii = 0; ii < N; ii = ii + 1) begin
                        data_real_out[ii] <= scaled_re[ii];
                        data_imag_out[ii] <= scaled_im[ii];
                    end

                    done  <= 1'b1;
                    state <= S_DONE;
                end

                S_DONE: begin
                    done <= 1'b1;

                    if (start) begin
                        done      <= 1'b0;
                        mode_reg  <= mode;
                        stage_cnt <= {STAGE_W{1'b0}};
                        j_cnt     <= {IDX_W{1'b0}};
                        group_cnt <= {IDX_W{1'b0}};

                        for (ii = 0; ii < N; ii = ii + 1) begin
                            mem_re[ii] <= {{GAIN_W{data_real_in[bitrev_idx[ii]][DATA_W-1]}},
                                           data_real_in[bitrev_idx[ii]]};
                            mem_im[ii] <= {{GAIN_W{data_imag_in[bitrev_idx[ii]][DATA_W-1]}},
                                           data_imag_in[bitrev_idx[ii]]};
                        end

                        state <= S_COMPUTE;
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