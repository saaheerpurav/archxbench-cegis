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
    output reg signed [DATA_W+GAIN_W-1:0] data_real_out [0:N-1],
    output reg signed [DATA_W+GAIN_W-1:0] data_imag_out [0:N-1],
    output reg done
);

    localparam OUT_W = DATA_W + GAIN_W;
    localparam ST_IDLE = 2'd0;
    localparam ST_RUN  = 2'd1;
    localparam ST_OUT  = 2'd2;
    localparam ST_DONE = 2'd3;

    reg [1:0] state;
    reg [1:0] stage;
    reg [3:0] butterfly;

    reg signed [OUT_W-1:0] mem_real [0:N-1];
    reg signed [OUT_W-1:0] mem_imag [0:N-1];

    wire [3:0] p_addr;
    wire [3:0] q_addr;
    wire [3:0] tw_addr;

    wire signed [COEFF_W-1:0] tw_cos;
    wire signed [COEFF_W-1:0] tw_sin;

    wire signed [OUT_W-1:0] y0_real;
    wire signed [OUT_W-1:0] y0_imag;
    wire signed [OUT_W-1:0] y1_real;
    wire signed [OUT_W-1:0] y1_imag;

    wire signed [OUT_W-1:0] load_real [0:N-1];
    wire signed [OUT_W-1:0] load_imag [0:N-1];

    integer i;

    fft16_bit_reverse_loader #(
        .N(N),
        .DATA_W(DATA_W),
        .OUT_W(OUT_W)
    ) u_loader (
        .data_real_in(data_real_in),
        .data_imag_in(data_imag_in),
        .data_real_out(load_real),
        .data_imag_out(load_imag)
    );

    fft16_addr_gen #(
        .N(N)
    ) u_addr (
        .stage(stage),
        .butterfly(butterfly),
        .p_addr(p_addr),
        .q_addr(q_addr),
        .tw_addr(tw_addr)
    );

    fft16_twiddle_rom #(
        .COEFF_W(COEFF_W)
    ) u_twiddle (
        .addr(tw_addr),
        .cos_q15(tw_cos),
        .sin_q15(tw_sin)
    );

    fft16_butterfly #(
        .DATA_W(OUT_W),
        .COEFF_W(COEFF_W)
    ) u_butterfly (
        .mode(mode),
        .a_real(mem_real[p_addr]),
        .a_imag(mem_imag[p_addr]),
        .b_real(mem_real[q_addr]),
        .b_imag(mem_imag[q_addr]),
        .tw_cos(tw_cos),
        .tw_sin(tw_sin),
        .y0_real(y0_real),
        .y0_imag(y0_imag),
        .y1_real(y1_real),
        .y1_imag(y1_imag)
    );

    always @(posedge clk) begin
        if (rst) begin
            state <= ST_IDLE;
            stage <= 2'd0;
            butterfly <= 4'd0;
            done <= 1'b0;
            for (i = 0; i < N; i = i + 1) begin
                mem_real[i] <= {OUT_W{1'b0}};
                mem_imag[i] <= {OUT_W{1'b0}};
                data_real_out[i] <= {OUT_W{1'b0}};
                data_imag_out[i] <= {OUT_W{1'b0}};
            end
        end else begin
            case (state)
                ST_IDLE: begin
                    done <= 1'b0;
                    stage <= 2'd0;
                    butterfly <= 4'd0;
                    if (start) begin
                        for (i = 0; i < N; i = i + 1) begin
                            mem_real[i] <= load_real[i];
                            mem_imag[i] <= load_imag[i];
                        end
                        state <= ST_RUN;
                    end
                end

                ST_RUN: begin
                    mem_real[p_addr] <= y0_real;
                    mem_imag[p_addr] <= y0_imag;
                    mem_real[q_addr] <= y1_real;
                    mem_imag[q_addr] <= y1_imag;

                    if (butterfly == 4'd7) begin
                        butterfly <= 4'd0;
                        if (stage == 2'd3) begin
                            state <= ST_OUT;
                        end else begin
                            stage <= stage + 2'd1;
                        end
                    end else begin
                        butterfly <= butterfly + 4'd1;
                    end
                end

                ST_OUT: begin
                    for (i = 0; i < N; i = i + 1) begin
                        if (mode) begin
                            data_real_out[i] <= mem_real[i] >>> 4;
                            data_imag_out[i] <= mem_imag[i] >>> 4;
                        end else begin
                            data_real_out[i] <= mem_real[i];
                            data_imag_out[i] <= mem_imag[i];
                        end
                    end
                    done <= 1'b1;
                    state <= ST_DONE;
                end

                ST_DONE: begin
                    done <= 1'b1;
                    if (start) begin
                        done <= 1'b0;
                        stage <= 2'd0;
                        butterfly <= 4'd0;
                        for (i = 0; i < N; i = i + 1) begin
                            mem_real[i] <= load_real[i];
                            mem_imag[i] <= load_imag[i];
                        end
                        state <= ST_RUN;
                    end
                end

                default: begin
                    state <= ST_IDLE;
                    done <= 1'b0;
                end
            endcase
        end
    end

endmodule