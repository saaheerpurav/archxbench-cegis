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
    localparam IDX_W = 4;

    localparam S_IDLE  = 3'd0;
    localparam S_LOAD  = 3'd1;
    localparam S_CALC  = 3'd2;
    localparam S_SCALE = 3'd3;
    localparam S_DONE  = 3'd4;

    reg [2:0] state;
    reg [IDX_W-1:0] load_idx;
    reg [IDX_W-1:0] butterfly_idx;
    reg [IDX_W-1:0] scale_idx;
    reg [1:0] stage;

    reg signed [OUT_W-1:0] mem_real [0:N-1];
    reg signed [OUT_W-1:0] mem_imag [0:N-1];
    reg signed [OUT_W-1:0] out_real_r [0:N-1];
    reg signed [OUT_W-1:0] out_imag_r [0:N-1];
    reg done_r;

    wire [IDX_W-1:0] bitrev_idx;
    wire [IDX_W-1:0] addr_p;
    wire [IDX_W-1:0] addr_q;
    wire [IDX_W-1:0] tw_idx;

    wire signed [COEFF_W-1:0] tw_cos;
    wire signed [COEFF_W-1:0] tw_sin;

    wire signed [OUT_W-1:0] bf_p_real_out;
    wire signed [OUT_W-1:0] bf_p_imag_out;
    wire signed [OUT_W-1:0] bf_q_real_out;
    wire signed [OUT_W-1:0] bf_q_imag_out;

    genvar gi;
    generate
        for (gi = 0; gi < N; gi = gi + 1) begin : OUT_ASSIGN
            assign data_real_out[gi] = out_real_r[gi];
            assign data_imag_out[gi] = out_imag_r[gi];
        end
    endgenerate

    assign done = done_r;

    ifft16_bit_reverse u_bit_reverse (
        .index_in(load_idx),
        .index_out(bitrev_idx)
    );

    ifft16_addr_gen u_addr_gen (
        .stage(stage),
        .butterfly_idx(butterfly_idx),
        .addr_p(addr_p),
        .addr_q(addr_q),
        .twiddle_idx(tw_idx)
    );

    ifft16_twiddle_rom #(
        .COEFF_W(COEFF_W)
    ) u_twiddle_rom (
        .twiddle_idx(tw_idx),
        .cos_q15(tw_cos),
        .sin_q15(tw_sin)
    );

    ifft16_butterfly #(
        .DATA_W(OUT_W),
        .COEFF_W(COEFF_W)
    ) u_butterfly (
        .a_real(mem_real[addr_p]),
        .a_imag(mem_imag[addr_p]),
        .b_real(mem_real[addr_q]),
        .b_imag(mem_imag[addr_q]),
        .tw_cos(tw_cos),
        .tw_sin(tw_sin),
        .p_real_out(bf_p_real_out),
        .p_imag_out(bf_p_imag_out),
        .q_real_out(bf_q_real_out),
        .q_imag_out(bf_q_imag_out)
    );

    integer i;
    always @(posedge clk) begin
        if (rst) begin
            state <= S_IDLE;
            load_idx <= 0;
            butterfly_idx <= 0;
            scale_idx <= 0;
            stage <= 0;
            done_r <= 1'b0;
            for (i = 0; i < N; i = i + 1) begin
                mem_real[i] <= 0;
                mem_imag[i] <= 0;
                out_real_r[i] <= 0;
                out_imag_r[i] <= 0;
            end
        end else begin
            case (state)
                S_IDLE: begin
                    done_r <= 1'b0;
                    if (start) begin
                        load_idx <= 0;
                        state <= S_LOAD;
                    end
                end

                S_LOAD: begin
                    mem_real[bitrev_idx] <= {{GAIN_W{data_real_in[load_idx][DATA_W-1]}}, data_real_in[load_idx]};
                    mem_imag[bitrev_idx] <= {{GAIN_W{data_imag_in[load_idx][DATA_W-1]}}, data_imag_in[load_idx]};

                    if (load_idx == N-1) begin
                        load_idx <= 0;
                        stage <= 0;
                        butterfly_idx <= 0;
                        state <= S_CALC;
                    end else begin
                        load_idx <= load_idx + 1'b1;
                    end
                end

                S_CALC: begin
                    mem_real[addr_p] <= bf_p_real_out;
                    mem_imag[addr_p] <= bf_p_imag_out;
                    mem_real[addr_q] <= bf_q_real_out;
                    mem_imag[addr_q] <= bf_q_imag_out;

                    if (butterfly_idx == (N/2)-1) begin
                        butterfly_idx <= 0;
                        if (stage == 2'd3) begin
                            scale_idx <= 0;
                            state <= S_SCALE;
                        end else begin
                            stage <= stage + 1'b1;
                        end
                    end else begin
                        butterfly_idx <= butterfly_idx + 1'b1;
                    end
                end

                S_SCALE: begin
                    out_real_r[scale_idx] <= mem_real[scale_idx] >>> GAIN_W;
                    out_imag_r[scale_idx] <= mem_imag[scale_idx] >>> GAIN_W;

                    if (scale_idx == N-1) begin
                        done_r <= 1'b1;
                        state <= S_DONE;
                    end else begin
                        scale_idx <= scale_idx + 1'b1;
                    end
                end

                S_DONE: begin
                    done_r <= 1'b1;
                    if (start) begin
                        done_r <= 1'b0;
                        load_idx <= 0;
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