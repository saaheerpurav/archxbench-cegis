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
    output done
);

    function integer clog2;
        input integer value;
        integer v;
        begin
            v = value - 1;
            clog2 = 0;
            while (v > 0) begin
                v = v >> 1;
                clog2 = clog2 + 1;
            end
        end
    endfunction

    localparam OUT_W   = DATA_W + GAIN_W;
    localparam STAGES  = clog2(N);
    localparam ADDR_W  = (N <= 2) ? 1 : clog2(N);
    localparam STAGE_W = (STAGES <= 1) ? 1 : clog2(STAGES);

    reg signed [OUT_W-1:0] mem_real [0:N-1];
    reg signed [OUT_W-1:0] mem_imag [0:N-1];

    wire signed [OUT_W-1:0] load_real [0:N-1];
    wire signed [OUT_W-1:0] load_imag [0:N-1];

    reg [STAGE_W-1:0] stage;
    reg [ADDR_W-1:0]  butterfly_idx;
    reg               busy;
    reg               done_reg;
    reg               mode_reg;

    wire [ADDR_W-1:0] addr_p;
    wire [ADDR_W-1:0] addr_q;
    wire [ADDR_W-1:0] tw_index;

    wire signed [COEFF_W-1:0] tw_cos;
    wire signed [COEFF_W-1:0] tw_sin_mag;
    wire signed [COEFF_W-1:0] tw_sin_eff;

    wire signed [OUT_W-1:0] bfly_p_real;
    wire signed [OUT_W-1:0] bfly_p_imag;
    wire signed [OUT_W-1:0] bfly_q_real;
    wire signed [OUT_W-1:0] bfly_q_imag;

    integer i;

    assign done = done_reg;
    assign tw_sin_eff = mode_reg ? -tw_sin_mag : tw_sin_mag;

    fft16_bit_reverse_loader #(
        .N(N),
        .DATA_W(DATA_W),
        .OUT_W(OUT_W)
    ) u_loader (
        .data_real_in(data_real_in),
        .data_imag_in(data_imag_in),
        .load_real(load_real),
        .load_imag(load_imag)
    );

    fft16_addr_gen #(
        .N(N),
        .ADDR_W(ADDR_W),
        .STAGE_W(STAGE_W)
    ) u_addr_gen (
        .stage(stage),
        .butterfly(butterfly_idx),
        .addr_p(addr_p),
        .addr_q(addr_q),
        .tw_index(tw_index)
    );

    fft16_twiddle_rom #(
        .N(N),
        .COEFF_W(COEFF_W),
        .ADDR_W(ADDR_W)
    ) u_twiddle_rom (
        .tw_index(tw_index),
        .cos_q15(tw_cos),
        .sin_q15(tw_sin_mag)
    );

    fft16_butterfly #(
        .IN_W(OUT_W),
        .COEFF_W(COEFF_W)
    ) u_butterfly (
        .xp_real(mem_real[addr_p]),
        .xp_imag(mem_imag[addr_p]),
        .xq_real(mem_real[addr_q]),
        .xq_imag(mem_imag[addr_q]),
        .tw_cos(tw_cos),
        .tw_sin(tw_sin_eff),
        .yp_real(bfly_p_real),
        .yp_imag(bfly_p_imag),
        .yq_real(bfly_q_real),
        .yq_imag(bfly_q_imag)
    );

    fft16_output_scale #(
        .N(N),
        .OUT_W(OUT_W)
    ) u_output_scale (
        .mode(mode_reg),
        .data_real_mem(mem_real),
        .data_imag_mem(mem_imag),
        .data_real_out(data_real_out),
        .data_imag_out(data_imag_out)
    );

    always @(posedge clk) begin
        if (rst) begin
            busy          <= 1'b0;
            done_reg      <= 1'b0;
            mode_reg      <= 1'b0;
            stage         <= {STAGE_W{1'b0}};
            butterfly_idx <= {ADDR_W{1'b0}};
            for (i = 0; i < N; i = i + 1) begin
                mem_real[i] <= {OUT_W{1'b0}};
                mem_imag[i] <= {OUT_W{1'b0}};
            end
        end else begin
            if (start && !busy) begin
                busy          <= 1'b1;
                done_reg      <= 1'b0;
                mode_reg      <= mode;
                stage         <= {STAGE_W{1'b0}};
                butterfly_idx <= {ADDR_W{1'b0}};
                for (i = 0; i < N; i = i + 1) begin
                    mem_real[i] <= load_real[i];
                    mem_imag[i] <= load_imag[i];
                end
            end else if (busy) begin
                mem_real[addr_p] <= bfly_p_real;
                mem_imag[addr_p] <= bfly_p_imag;
                mem_real[addr_q] <= bfly_q_real;
                mem_imag[addr_q] <= bfly_q_imag;

                if ((stage == STAGES-1) && (butterfly_idx == (N/2)-1)) begin
                    busy          <= 1'b0;
                    done_reg      <= 1'b1;
                    stage         <= stage;
                    butterfly_idx <= butterfly_idx;
                end else begin
                    done_reg <= 1'b0;
                    if (butterfly_idx == (N/2)-1) begin
                        butterfly_idx <= {ADDR_W{1'b0}};
                        stage         <= stage + {{(STAGE_W-1){1'b0}}, 1'b1};
                    end else begin
                        butterfly_idx <= butterfly_idx + {{(ADDR_W-1){1'b0}}, 1'b1};
                        stage         <= stage;
                    end
                end
            end
        end
    end

endmodule