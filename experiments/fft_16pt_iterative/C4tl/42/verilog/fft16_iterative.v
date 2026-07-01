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

    localparam OUT_W  = DATA_W + GAIN_W;
    localparam STAGES = 4;
    localparam BFLY_W = 3;

    localparam S_IDLE = 2'd0;
    localparam S_RUN  = 2'd1;
    localparam S_DONE = 2'd2;

    reg [1:0] state;
    reg [1:0] stage;
    reg [BFLY_W-1:0] bfly;
    reg mode_r;

    reg signed [OUT_W-1:0] mem_real [0:N-1];
    reg signed [OUT_W-1:0] mem_imag [0:N-1];

    wire [3:0] br_idx [0:N-1];

    genvar gi;
    generate
        for (gi = 0; gi < N; gi = gi + 1) begin : GEN_BITREV
            fft16_bit_reverse u_bit_reverse (
                .index_in (gi[3:0]),
                .index_out(br_idx[gi])
            );
        end
    endgenerate

    wire [3:0] half_w;
    wire [3:0] span_w;
    wire [3:0] j_w;
    wire [3:0] group_w;
    wire [3:0] p_idx;
    wire [3:0] q_idx;
    wire [3:0] tw_idx;

    assign half_w  = 4'd1 << stage;
    assign span_w  = half_w << 1;
    assign j_w     = {1'b0, bfly} & (half_w - 4'd1);
    assign group_w = ({1'b0, bfly} >> stage) << (stage + 1'b1);
    assign p_idx   = group_w + j_w;
    assign q_idx   = p_idx + half_w;
    assign tw_idx  = j_w << (STAGES - 1 - stage);

    wire signed [COEFF_W-1:0] tw_cos;
    wire signed [COEFF_W-1:0] tw_sin;

    fft16_twiddle_rom #(
        .COEFF_W(COEFF_W)
    ) u_twiddle_rom (
        .tw_idx(tw_idx),
        .cos_q (tw_cos),
        .sin_q (tw_sin)
    );

    wire signed [OUT_W-1:0] bf_a_real;
    wire signed [OUT_W-1:0] bf_a_imag;
    wire signed [OUT_W-1:0] bf_b_real;
    wire signed [OUT_W-1:0] bf_b_imag;

    fft16_butterfly #(
        .DATA_W (OUT_W),
        .COEFF_W(COEFF_W)
    ) u_butterfly (
        .a_real    (mem_real[p_idx]),
        .a_imag    (mem_imag[p_idx]),
        .b_real    (mem_real[q_idx]),
        .b_imag    (mem_imag[q_idx]),
        .tw_cos    (tw_cos),
        .tw_sin    (tw_sin),
        .ifft_mode (mode_r),
        .y0_real   (bf_a_real),
        .y0_imag   (bf_a_imag),
        .y1_real   (bf_b_real),
        .y1_imag   (bf_b_imag)
    );

    generate
        for (gi = 0; gi < N; gi = gi + 1) begin : GEN_OUTPUTS
            fft16_output_scale #(
                .DATA_W(DATA_W),
                .GAIN_W(GAIN_W)
            ) u_output_scale (
                .in_real  (mem_real[gi]),
                .in_imag  (mem_imag[gi]),
                .ifft_mode(mode_r),
                .out_real (data_real_out[gi]),
                .out_imag (data_imag_out[gi])
            );
        end
    endgenerate

    assign done = (state == S_DONE);

    integer i;
    always @(posedge clk) begin
        if (rst) begin
            state  <= S_IDLE;
            stage  <= 2'd0;
            bfly   <= {BFLY_W{1'b0}};
            mode_r <= 1'b0;
            for (i = 0; i < N; i = i + 1) begin
                mem_real[i] <= {OUT_W{1'b0}};
                mem_imag[i] <= {OUT_W{1'b0}};
            end
        end else begin
            case (state)
                S_IDLE: begin
                    if (start) begin
                        mode_r <= mode;
                        stage  <= 2'd0;
                        bfly   <= {BFLY_W{1'b0}};
                        for (i = 0; i < N; i = i + 1) begin
                            mem_real[br_idx[i]] <= {{GAIN_W{data_real_in[i][DATA_W-1]}}, data_real_in[i]};
                            mem_imag[br_idx[i]] <= {{GAIN_W{data_imag_in[i][DATA_W-1]}}, data_imag_in[i]};
                        end
                        state <= S_RUN;
                    end
                end

                S_RUN: begin
                    mem_real[p_idx] <= bf_a_real;
                    mem_imag[p_idx] <= bf_a_imag;
                    mem_real[q_idx] <= bf_b_real;
                    mem_imag[q_idx] <= bf_b_imag;

                    if ((stage == STAGES-1) && (bfly == (N/2)-1)) begin
                        state <= S_DONE;
                    end else if (bfly == (N/2)-1) begin
                        bfly  <= {BFLY_W{1'b0}};
                        stage <= stage + 2'd1;
                    end else begin
                        bfly <= bfly + {{(BFLY_W-1){1'b0}}, 1'b1};
                    end
                end

                S_DONE: begin
                    if (start) begin
                        mode_r <= mode;
                        stage  <= 2'd0;
                        bfly   <= {BFLY_W{1'b0}};
                        for (i = 0; i < N; i = i + 1) begin
                            mem_real[br_idx[i]] <= {{GAIN_W{data_real_in[i][DATA_W-1]}}, data_real_in[i]};
                            mem_imag[br_idx[i]] <= {{GAIN_W{data_imag_in[i][DATA_W-1]}}, data_imag_in[i]};
                        end
                        state <= S_RUN;
                    end
                end

                default: begin
                    state <= S_IDLE;
                end
            endcase
        end
    end

endmodule