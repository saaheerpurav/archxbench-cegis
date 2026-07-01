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
    input mode,
    input signed [DATA_W-1:0] data_real_in [0:N-1],
    input signed [DATA_W-1:0] data_imag_in [0:N-1],
    output signed [DATA_W+GAIN_W-1:0] data_real_out [0:N-1],
    output signed [DATA_W+GAIN_W-1:0] data_imag_out [0:N-1],
    output done
);

    localparam OUT_W = DATA_W + GAIN_W;
    localparam STAGES = 4;
    localparam BF_PER_STAGE = N / 2;

    localparam S_IDLE    = 2'd0;
    localparam S_PROCESS = 2'd1;
    localparam S_DONE    = 2'd2;

    reg [1:0] state;
    reg [2:0] stage;
    reg [3:0] butterfly_index;
    reg done_r;

    reg signed [OUT_W-1:0] mem_real [0:N-1];
    reg signed [OUT_W-1:0] mem_imag [0:N-1];

    wire [3:0] p_idx;
    wire [3:0] q_idx;
    wire [3:0] tw_idx;

    wire signed [COEFF_W-1:0] tw_cos;
    wire signed [COEFF_W-1:0] tw_sin;

    wire signed [OUT_W-1:0] bf_p_real;
    wire signed [OUT_W-1:0] bf_p_imag;
    wire signed [OUT_W-1:0] bf_q_real;
    wire signed [OUT_W-1:0] bf_q_imag;

    wire [3:0] br0, br1, br2, br3, br4, br5, br6, br7;
    wire [3:0] br8, br9, br10, br11, br12, br13, br14, br15;

    assign done = done_r;

    genvar gi;
    generate
        for (gi = 0; gi < N; gi = gi + 1) begin : OUT_ASSIGN
            assign data_real_out[gi] = mem_real[gi];
            assign data_imag_out[gi] = mem_imag[gi];
        end
    endgenerate

    fft16_bit_reverse u_br0  (.index_in(4'd0),  .index_out(br0));
    fft16_bit_reverse u_br1  (.index_in(4'd1),  .index_out(br1));
    fft16_bit_reverse u_br2  (.index_in(4'd2),  .index_out(br2));
    fft16_bit_reverse u_br3  (.index_in(4'd3),  .index_out(br3));
    fft16_bit_reverse u_br4  (.index_in(4'd4),  .index_out(br4));
    fft16_bit_reverse u_br5  (.index_in(4'd5),  .index_out(br5));
    fft16_bit_reverse u_br6  (.index_in(4'd6),  .index_out(br6));
    fft16_bit_reverse u_br7  (.index_in(4'd7),  .index_out(br7));
    fft16_bit_reverse u_br8  (.index_in(4'd8),  .index_out(br8));
    fft16_bit_reverse u_br9  (.index_in(4'd9),  .index_out(br9));
    fft16_bit_reverse u_br10 (.index_in(4'd10), .index_out(br10));
    fft16_bit_reverse u_br11 (.index_in(4'd11), .index_out(br11));
    fft16_bit_reverse u_br12 (.index_in(4'd12), .index_out(br12));
    fft16_bit_reverse u_br13 (.index_in(4'd13), .index_out(br13));
    fft16_bit_reverse u_br14 (.index_in(4'd14), .index_out(br14));
    fft16_bit_reverse u_br15 (.index_in(4'd15), .index_out(br15));

    fft16_address_gen u_addr (
        .stage(stage[1:0]),
        .butterfly_index(butterfly_index[2:0]),
        .p_idx(p_idx),
        .q_idx(q_idx),
        .tw_idx(tw_idx)
    );

    fft16_twiddle_rom #(
        .COEFF_W(COEFF_W)
    ) u_twiddle (
        .tw_idx(tw_idx),
        .mode(mode),
        .cos_q15(tw_cos),
        .sin_q15(tw_sin)
    );

    fft16_butterfly #(
        .DATA_W(OUT_W),
        .COEFF_W(COEFF_W)
    ) u_butterfly (
        .a_real(mem_real[p_idx]),
        .a_imag(mem_imag[p_idx]),
        .b_real(mem_real[q_idx]),
        .b_imag(mem_imag[q_idx]),
        .tw_cos(tw_cos),
        .tw_sin(tw_sin),
        .y0_real(bf_p_real),
        .y0_imag(bf_p_imag),
        .y1_real(bf_q_real),
        .y1_imag(bf_q_imag)
    );

    integer i;

    always @(posedge clk) begin
        if (rst) begin
            state <= S_IDLE;
            stage <= 3'd0;
            butterfly_index <= 4'd0;
            done_r <= 1'b0;
            for (i = 0; i < N; i = i + 1) begin
                mem_real[i] <= {OUT_W{1'b0}};
                mem_imag[i] <= {OUT_W{1'b0}};
            end
        end else begin
            case (state)
                S_IDLE: begin
                    done_r <= 1'b0;
                    stage <= 3'd0;
                    butterfly_index <= 4'd0;

                    if (start) begin
                        mem_real[0]  <= {{GAIN_W{data_real_in[br0][DATA_W-1]}},  data_real_in[br0]};
                        mem_imag[0]  <= {{GAIN_W{data_imag_in[br0][DATA_W-1]}},  data_imag_in[br0]};
                        mem_real[1]  <= {{GAIN_W{data_real_in[br1][DATA_W-1]}},  data_real_in[br1]};
                        mem_imag[1]  <= {{GAIN_W{data_imag_in[br1][DATA_W-1]}},  data_imag_in[br1]};
                        mem_real[2]  <= {{GAIN_W{data_real_in[br2][DATA_W-1]}},  data_real_in[br2]};
                        mem_imag[2]  <= {{GAIN_W{data_imag_in[br2][DATA_W-1]}},  data_imag_in[br2]};
                        mem_real[3]  <= {{GAIN_W{data_real_in[br3][DATA_W-1]}},  data_real_in[br3]};
                        mem_imag[3]  <= {{GAIN_W{data_imag_in[br3][DATA_W-1]}},  data_imag_in[br3]};
                        mem_real[4]  <= {{GAIN_W{data_real_in[br4][DATA_W-1]}},  data_real_in[br4]};
                        mem_imag[4]  <= {{GAIN_W{data_imag_in[br4][DATA_W-1]}},  data_imag_in[br4]};
                        mem_real[5]  <= {{GAIN_W{data_real_in[br5][DATA_W-1]}},  data_real_in[br5]};
                        mem_imag[5]  <= {{GAIN_W{data_imag_in[br5][DATA_W-1]}},  data_imag_in[br5]};
                        mem_real[6]  <= {{GAIN_W{data_real_in[br6][DATA_W-1]}},  data_real_in[br6]};
                        mem_imag[6]  <= {{GAIN_W{data_imag_in[br6][DATA_W-1]}},  data_imag_in[br6]};
                        mem_real[7]  <= {{GAIN_W{data_real_in[br7][DATA_W-1]}},  data_real_in[br7]};
                        mem_imag[7]  <= {{GAIN_W{data_imag_in[br7][DATA_W-1]}},  data_imag_in[br7]};
                        mem_real[8]  <= {{GAIN_W{data_real_in[br8][DATA_W-1]}},  data_real_in[br8]};
                        mem_imag[8]  <= {{GAIN_W{data_imag_in[br8][DATA_W-1]}},  data_imag_in[br8]};
                        mem_real[9]  <= {{GAIN_W{data_real_in[br9][DATA_W-1]}},  data_real_in[br9]};
                        mem_imag[9]  <= {{GAIN_W{data_imag_in[br9][DATA_W-1]}},  data_imag_in[br9]};
                        mem_real[10] <= {{GAIN_W{data_real_in[br10][DATA_W-1]}}, data_real_in[br10]};
                        mem_imag[10] <= {{GAIN_W{data_imag_in[br10][DATA_W-1]}}, data_imag_in[br10]};
                        mem_real[11] <= {{GAIN_W{data_real_in[br11][DATA_W-1]}}, data_real_in[br11]};
                        mem_imag[11] <= {{GAIN_W{data_imag_in[br11][DATA_W-1]}}, data_imag_in[br11]};
                        mem_real[12] <= {{GAIN_W{data_real_in[br12][DATA_W-1]}}, data_real_in[br12]};
                        mem_imag[12] <= {{GAIN_W{data_imag_in[br12][DATA_W-1]}}, data_imag_in[br12]};
                        mem_real[13] <= {{GAIN_W{data_real_in[br13][DATA_W-1]}}, data_real_in[br13]};
                        mem_imag[13] <= {{GAIN_W{data_imag_in[br13][DATA_W-1]}}, data_imag_in[br13]};
                        mem_real[14] <= {{GAIN_W{data_real_in[br14][DATA_W-1]}}, data_real_in[br14]};
                        mem_imag[14] <= {{GAIN_W{data_imag_in[br14][DATA_W-1]}}, data_imag_in[br14]};
                        mem_real[15] <= {{GAIN_W{data_real_in[br15][DATA_W-1]}}, data_real_in[br15]};
                        mem_imag[15] <= {{GAIN_W{data_imag_in[br15][DATA_W-1]}}, data_imag_in[br15]};
                        state <= S_PROCESS;
                    end
                end

                S_PROCESS: begin
                    mem_real[p_idx] <= bf_p_real;
                    mem_imag[p_idx] <= bf_p_imag;
                    mem_real[q_idx] <= bf_q_real;
                    mem_imag[q_idx] <= bf_q_imag;

                    if (butterfly_index == BF_PER_STAGE - 1) begin
                        butterfly_index <= 4'd0;
                        if (stage == STAGES - 1) begin
                            state <= S_DONE;
                        end else begin
                            stage <= stage + 3'd1;
                        end
                    end else begin
                        butterfly_index <= butterfly_index + 4'd1;
                    end
                end

                S_DONE: begin
                    for (i = 0; i < N; i = i + 1) begin
                        mem_real[i] <= mem_real[i] >>> 4;
                        mem_imag[i] <= mem_imag[i] >>> 4;
                    end
                    done_r <= 1'b1;
                    state <= S_IDLE;
                end

                default: begin
                    state <= S_IDLE;
                    done_r <= 1'b0;
                end
            endcase
        end
    end

endmodule