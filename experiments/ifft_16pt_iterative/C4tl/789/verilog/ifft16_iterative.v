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

    localparam OUT_W   = DATA_W + GAIN_W;
    localparam ADDR_W  = 4;
    localparam STAGE_W = 3;
    localparam COUNT_W = 4;

    localparam S_IDLE = 2'd0;
    localparam S_RUN  = 2'd1;
    localparam S_DONE = 2'd2;

    reg [1:0] state;
    reg done_r;

    reg [STAGE_W-1:0] stage;
    reg [COUNT_W-1:0] butterfly;

    reg signed [OUT_W-1:0] mem_real [0:N-1];
    reg signed [OUT_W-1:0] mem_imag [0:N-1];

    wire [ADDR_W-1:0] p_addr;
    wire [ADDR_W-1:0] q_addr;
    wire [ADDR_W-1:0] tw_idx;

    wire signed [COEFF_W-1:0] tw_cos;
    wire signed [COEFF_W-1:0] tw_sin;

    wire signed [OUT_W-1:0] a_real = mem_real[p_addr];
    wire signed [OUT_W-1:0] a_imag = mem_imag[p_addr];
    wire signed [OUT_W-1:0] b_real = mem_real[q_addr];
    wire signed [OUT_W-1:0] b_imag = mem_imag[q_addr];

    wire signed [OUT_W-1:0] y0_real;
    wire signed [OUT_W-1:0] y0_imag;
    wire signed [OUT_W-1:0] y1_real;
    wire signed [OUT_W-1:0] y1_imag;

    integer i;

    assign done = done_r;

    ifft16_pair_index u_pair_index (
        .stage(stage),
        .butterfly(butterfly),
        .p_addr(p_addr),
        .q_addr(q_addr),
        .tw_idx(tw_idx)
    );

    ifft16_twiddle_rom #(
        .COEFF_W(COEFF_W)
    ) u_twiddle_rom (
        .tw_idx(tw_idx),
        .cos_q15(tw_cos),
        .sin_q15(tw_sin)
    );

    ifft16_butterfly #(
        .DATA_W(OUT_W),
        .COEFF_W(COEFF_W)
    ) u_butterfly (
        .a_real(a_real),
        .a_imag(a_imag),
        .b_real(b_real),
        .b_imag(b_imag),
        .tw_cos(tw_cos),
        .tw_sin(tw_sin),
        .y0_real(y0_real),
        .y0_imag(y0_imag),
        .y1_real(y1_real),
        .y1_imag(y1_imag)
    );

    genvar gi;
    generate
        for (gi = 0; gi < N; gi = gi + 1) begin : GEN_OUTPUTS
            ifft16_output_scale #(
                .IN_W(OUT_W),
                .SHIFT(GAIN_W)
            ) u_scale_real (
                .din(mem_real[gi]),
                .dout(data_real_out[gi])
            );

            ifft16_output_scale #(
                .IN_W(OUT_W),
                .SHIFT(GAIN_W)
            ) u_scale_imag (
                .din(mem_imag[gi]),
                .dout(data_imag_out[gi])
            );
        end
    endgenerate

    always @(posedge clk) begin
        if (rst) begin
            state <= S_IDLE;
            done_r <= 1'b0;
            stage <= {STAGE_W{1'b0}};
            butterfly <= {COUNT_W{1'b0}};
            for (i = 0; i < N; i = i + 1) begin
                mem_real[i] <= {OUT_W{1'b0}};
                mem_imag[i] <= {OUT_W{1'b0}};
            end
        end else begin
            case (state)
                S_IDLE: begin
                    done_r <= 1'b0;
                    stage <= {STAGE_W{1'b0}};
                    butterfly <= {COUNT_W{1'b0}};

                    if (start) begin
                        mem_real[0]  <= {{GAIN_W{data_real_in[0][DATA_W-1]}},  data_real_in[0]};
                        mem_imag[0]  <= {{GAIN_W{data_imag_in[0][DATA_W-1]}},  data_imag_in[0]};
                        mem_real[1]  <= {{GAIN_W{data_real_in[8][DATA_W-1]}},  data_real_in[8]};
                        mem_imag[1]  <= {{GAIN_W{data_imag_in[8][DATA_W-1]}},  data_imag_in[8]};
                        mem_real[2]  <= {{GAIN_W{data_real_in[4][DATA_W-1]}},  data_real_in[4]};
                        mem_imag[2]  <= {{GAIN_W{data_imag_in[4][DATA_W-1]}},  data_imag_in[4]};
                        mem_real[3]  <= {{GAIN_W{data_real_in[12][DATA_W-1]}}, data_real_in[12]};
                        mem_imag[3]  <= {{GAIN_W{data_imag_in[12][DATA_W-1]}}, data_imag_in[12]};
                        mem_real[4]  <= {{GAIN_W{data_real_in[2][DATA_W-1]}},  data_real_in[2]};
                        mem_imag[4]  <= {{GAIN_W{data_imag_in[2][DATA_W-1]}},  data_imag_in[2]};
                        mem_real[5]  <= {{GAIN_W{data_real_in[10][DATA_W-1]}}, data_real_in[10]};
                        mem_imag[5]  <= {{GAIN_W{data_imag_in[10][DATA_W-1]}}, data_imag_in[10]};
                        mem_real[6]  <= {{GAIN_W{data_real_in[6][DATA_W-1]}},  data_real_in[6]};
                        mem_imag[6]  <= {{GAIN_W{data_imag_in[6][DATA_W-1]}},  data_imag_in[6]};
                        mem_real[7]  <= {{GAIN_W{data_real_in[14][DATA_W-1]}}, data_real_in[14]};
                        mem_imag[7]  <= {{GAIN_W{data_imag_in[14][DATA_W-1]}}, data_imag_in[14]};
                        mem_real[8]  <= {{GAIN_W{data_real_in[1][DATA_W-1]}},  data_real_in[1]};
                        mem_imag[8]  <= {{GAIN_W{data_imag_in[1][DATA_W-1]}},  data_imag_in[1]};
                        mem_real[9]  <= {{GAIN_W{data_real_in[9][DATA_W-1]}},  data_real_in[9]};
                        mem_imag[9]  <= {{GAIN_W{data_imag_in[9][DATA_W-1]}},  data_imag_in[9]};
                        mem_real[10] <= {{GAIN_W{data_real_in[5][DATA_W-1]}},  data_real_in[5]};
                        mem_imag[10] <= {{GAIN_W{data_imag_in[5][DATA_W-1]}},  data_imag_in[5]};
                        mem_real[11] <= {{GAIN_W{data_real_in[13][DATA_W-1]}}, data_real_in[13]};
                        mem_imag[11] <= {{GAIN_W{data_imag_in[13][DATA_W-1]}}, data_imag_in[13]};
                        mem_real[12] <= {{GAIN_W{data_real_in[3][DATA_W-1]}},  data_real_in[3]};
                        mem_imag[12] <= {{GAIN_W{data_imag_in[3][DATA_W-1]}},  data_imag_in[3]};
                        mem_real[13] <= {{GAIN_W{data_real_in[11][DATA_W-1]}}, data_real_in[11]};
                        mem_imag[13] <= {{GAIN_W{data_imag_in[11][DATA_W-1]}}, data_imag_in[11]};
                        mem_real[14] <= {{GAIN_W{data_real_in[7][DATA_W-1]}},  data_real_in[7]};
                        mem_imag[14] <= {{GAIN_W{data_imag_in[7][DATA_W-1]}},  data_imag_in[7]};
                        mem_real[15] <= {{GAIN_W{data_real_in[15][DATA_W-1]}}, data_real_in[15]};
                        mem_imag[15] <= {{GAIN_W{data_imag_in[15][DATA_W-1]}}, data_imag_in[15]};
                        state <= S_RUN;
                    end
                end

                S_RUN: begin
                    mem_real[p_addr] <= y0_real;
                    mem_imag[p_addr] <= y0_imag;
                    mem_real[q_addr] <= y1_real;
                    mem_imag[q_addr] <= y1_imag;

                    if (butterfly == 4'd7) begin
                        butterfly <= 4'd0;
                        if (stage == 3'd3) begin
                            state <= S_DONE;
                            done_r <= 1'b1;
                        end else begin
                            stage <= stage + 3'd1;
                        end
                    end else begin
                        butterfly <= butterfly + 4'd1;
                    end
                end

                S_DONE: begin
                    done_r <= 1'b1;
                    if (start) begin
                        done_r <= 1'b0;
                        stage <= {STAGE_W{1'b0}};
                        butterfly <= {COUNT_W{1'b0}};

                        mem_real[0]  <= {{GAIN_W{data_real_in[0][DATA_W-1]}},  data_real_in[0]};
                        mem_imag[0]  <= {{GAIN_W{data_imag_in[0][DATA_W-1]}},  data_imag_in[0]};
                        mem_real[1]  <= {{GAIN_W{data_real_in[8][DATA_W-1]}},  data_real_in[8]};
                        mem_imag[1]  <= {{GAIN_W{data_imag_in[8][DATA_W-1]}},  data_imag_in[8]};
                        mem_real[2]  <= {{GAIN_W{data_real_in[4][DATA_W-1]}},  data_real_in[4]};
                        mem_imag[2]  <= {{GAIN_W{data_imag_in[4][DATA_W-1]}},  data_imag_in[4]};
                        mem_real[3]  <= {{GAIN_W{data_real_in[12][DATA_W-1]}}, data_real_in[12]};
                        mem_imag[3]  <= {{GAIN_W{data_imag_in[12][DATA_W-1]}}, data_imag_in[12]};
                        mem_real[4]  <= {{GAIN_W{data_real_in[2][DATA_W-1]}},  data_real_in[2]};
                        mem_imag[4]  <= {{GAIN_W{data_imag_in[2][DATA_W-1]}},  data_imag_in[2]};
                        mem_real[5]  <= {{GAIN_W{data_real_in[10][DATA_W-1]}}, data_real_in[10]};
                        mem_imag[5]  <= {{GAIN_W{data_imag_in[10][DATA_W-1]}}, data_imag_in[10]};
                        mem_real[6]  <= {{GAIN_W{data_real_in[6][DATA_W-1]}},  data_real_in[6]};
                        mem_imag[6]  <= {{GAIN_W{data_imag_in[6][DATA_W-1]}},  data_imag_in[6]};
                        mem_real[7]  <= {{GAIN_W{data_real_in[14][DATA_W-1]}}, data_real_in[14]};
                        mem_imag[7]  <= {{GAIN_W{data_imag_in[14][DATA_W-1]}}, data_imag_in[14]};
                        mem_real[8]  <= {{GAIN_W{data_real_in[1][DATA_W-1]}},  data_real_in[1]};
                        mem_imag[8]  <= {{GAIN_W{data_imag_in[1][DATA_W-1]}},  data_imag_in[1]};
                        mem_real[9]  <= {{GAIN_W{data_real_in[9][DATA_W-1]}},  data_real_in[9]};
                        mem_imag[9]  <= {{GAIN_W{data_imag_in[9][DATA_W-1]}},  data_imag_in[9]};
                        mem_real[10] <= {{GAIN_W{data_real_in[5][DATA_W-1]}},  data_real_in[5]};
                        mem_imag[10] <= {{GAIN_W{data_imag_in[5][DATA_W-1]}},  data_imag_in[5]};
                        mem_real[11] <= {{GAIN_W{data_real_in[13][DATA_W-1]}}, data_real_in[13]};
                        mem_imag[11] <= {{GAIN_W{data_imag_in[13][DATA_W-1]}}, data_imag_in[13]};
                        mem_real[12] <= {{GAIN_W{data_real_in[3][DATA_W-1]}},  data_real_in[3]};
                        mem_imag[12] <= {{GAIN_W{data_imag_in[3][DATA_W-1]}},  data_imag_in[3]};
                        mem_real[13] <= {{GAIN_W{data_real_in[11][DATA_W-1]}}, data_real_in[11]};
                        mem_imag[13] <= {{GAIN_W{data_imag_in[11][DATA_W-1]}}, data_imag_in[11]};
                        mem_real[14] <= {{GAIN_W{data_real_in[7][DATA_W-1]}},  data_real_in[7]};
                        mem_imag[14] <= {{GAIN_W{data_imag_in[7][DATA_W-1]}},  data_imag_in[7]};
                        mem_real[15] <= {{GAIN_W{data_real_in[15][DATA_W-1]}}, data_real_in[15]};
                        mem_imag[15] <= {{GAIN_W{data_imag_in[15][DATA_W-1]}}, data_imag_in[15]};
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