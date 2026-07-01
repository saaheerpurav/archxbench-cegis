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

    localparam OUT_W = DATA_W + GAIN_W;
    localparam ADDR_W = 4;

    localparam ST_IDLE    = 2'd0;
    localparam ST_LOAD    = 2'd1;
    localparam ST_COMPUTE = 2'd2;
    localparam ST_DONE    = 2'd3;

    reg [1:0] state;
    reg done_r;

    reg signed [OUT_W-1:0] mem_real [0:N-1];
    reg signed [OUT_W-1:0] mem_imag [0:N-1];
    reg signed [OUT_W-1:0] out_real_r [0:N-1];
    reg signed [OUT_W-1:0] out_imag_r [0:N-1];

    reg [ADDR_W-1:0] load_idx;
    reg [2:0] stage;
    reg [ADDR_W-1:0] group_base;
    reg [ADDR_W-1:0] j_idx;

    wire [ADDR_W-1:0] rev_idx;
    wire [ADDR_W-1:0] half_size;
    wire [ADDR_W:0]   step_size;
    wire [ADDR_W-1:0] p_addr;
    wire [ADDR_W-1:0] q_addr;
    wire [ADDR_W-1:0] tw_idx;

    wire signed [COEFF_W-1:0] tw_cos;
    wire signed [COEFF_W-1:0] tw_sin;

    wire signed [OUT_W-1:0] bf_p_real;
    wire signed [OUT_W-1:0] bf_p_imag;
    wire signed [OUT_W-1:0] bf_q_real;
    wire signed [OUT_W-1:0] bf_q_imag;

    integer i;

    ifft16_bit_reverse_addr u_bit_reverse_addr (
        .addr(load_idx),
        .rev_addr(rev_idx)
    );

    ifft16_stage_addr_gen u_stage_addr_gen (
        .stage(stage),
        .group_base(group_base),
        .j_idx(j_idx),
        .half_size(half_size),
        .step_size(step_size),
        .p_addr(p_addr),
        .q_addr(q_addr),
        .tw_idx(tw_idx)
    );

    ifft16_twiddle_rom #(
        .COEFF_W(COEFF_W)
    ) u_twiddle_rom (
        .idx(tw_idx),
        .ifft_mode(mode),
        .cos_o(tw_cos),
        .sin_o(tw_sin)
    );

    ifft16_butterfly #(
        .DATA_W(OUT_W),
        .COEFF_W(COEFF_W)
    ) u_butterfly (
        .a_real(mem_real[p_addr]),
        .a_imag(mem_imag[p_addr]),
        .b_real(mem_real[q_addr]),
        .b_imag(mem_imag[q_addr]),
        .tw_cos(tw_cos),
        .tw_sin(tw_sin),
        .y0_real(bf_p_real),
        .y0_imag(bf_p_imag),
        .y1_real(bf_q_real),
        .y1_imag(bf_q_imag)
    );

    assign done = done_r;

    genvar gi;
    generate
        for (gi = 0; gi < N; gi = gi + 1) begin : g_out
            assign data_real_out[gi] = out_real_r[gi];
            assign data_imag_out[gi] = out_imag_r[gi];
        end
    endgenerate

    always @(posedge clk) begin
        if (rst) begin
            state <= ST_IDLE;
            done_r <= 1'b0;
            load_idx <= {ADDR_W{1'b0}};
            stage <= 3'd0;
            group_base <= {ADDR_W{1'b0}};
            j_idx <= {ADDR_W{1'b0}};
            for (i = 0; i < N; i = i + 1) begin
                mem_real[i] <= {OUT_W{1'b0}};
                mem_imag[i] <= {OUT_W{1'b0}};
                out_real_r[i] <= {OUT_W{1'b0}};
                out_imag_r[i] <= {OUT_W{1'b0}};
            end
        end else begin
            case (state)
                ST_IDLE: begin
                    done_r <= 1'b0;
                    if (start) begin
                        load_idx <= {ADDR_W{1'b0}};
                        state <= ST_LOAD;
                    end
                end

                ST_LOAD: begin
                    mem_real[load_idx] <= {{GAIN_W{data_real_in[rev_idx][DATA_W-1]}}, data_real_in[rev_idx]};
                    mem_imag[load_idx] <= {{GAIN_W{data_imag_in[rev_idx][DATA_W-1]}}, data_imag_in[rev_idx]};

                    if (load_idx == N-1) begin
                        stage <= 3'd0;
                        group_base <= {ADDR_W{1'b0}};
                        j_idx <= {ADDR_W{1'b0}};
                        state <= ST_COMPUTE;
                    end else begin
                        load_idx <= load_idx + 1'b1;
                    end
                end

                ST_COMPUTE: begin
                    mem_real[p_addr] <= bf_p_real;
                    mem_imag[p_addr] <= bf_p_imag;
                    mem_real[q_addr] <= bf_q_real;
                    mem_imag[q_addr] <= bf_q_imag;

                    if (j_idx == half_size - 1'b1) begin
                        j_idx <= {ADDR_W{1'b0}};
                        if (group_base + step_size >= N) begin
                            group_base <= {ADDR_W{1'b0}};
                            if (stage == 3'd3) begin
                                for (i = 0; i < N; i = i + 1) begin
                                    if (i == p_addr) begin
                                        out_real_r[i] <= bf_p_real >>> 4;
                                        out_imag_r[i] <= bf_p_imag >>> 4;
                                    end else if (i == q_addr) begin
                                        out_real_r[i] <= bf_q_real >>> 4;
                                        out_imag_r[i] <= bf_q_imag >>> 4;
                                    end else begin
                                        out_real_r[i] <= mem_real[i] >>> 4;
                                        out_imag_r[i] <= mem_imag[i] >>> 4;
                                    end
                                end
                                done_r <= 1'b1;
                                state <= ST_DONE;
                            end else begin
                                stage <= stage + 1'b1;
                            end
                        end else begin
                            group_base <= group_base + step_size[ADDR_W-1:0];
                        end
                    end else begin
                        j_idx <= j_idx + 1'b1;
                    end
                end

                ST_DONE: begin
                    done_r <= 1'b1;
                    if (start) begin
                        done_r <= 1'b0;
                        load_idx <= {ADDR_W{1'b0}};
                        state <= ST_LOAD;
                    end
                end

                default: begin
                    state <= ST_IDLE;
                    done_r <= 1'b0;
                end
            endcase
        end
    end

endmodule