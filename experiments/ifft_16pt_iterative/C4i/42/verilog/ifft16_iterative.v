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

    function integer clog2_int;
        input integer value;
        integer v;
        begin
            v = value - 1;
            for (clog2_int = 0; v > 0; clog2_int = clog2_int + 1)
                v = v >> 1;
        end
    endfunction

    localparam OUT_W  = DATA_W + GAIN_W;
    localparam ADDR_W = clog2_int(N);
    localparam LOGN   = clog2_int(N);

    localparam ST_IDLE = 2'd0;
    localparam ST_LOAD = 2'd1;
    localparam ST_RUN  = 2'd2;
    localparam ST_DONE = 2'd3;

    reg [1:0] state;

    reg signed [OUT_W-1:0] mem_real [0:N-1];
    reg signed [OUT_W-1:0] mem_imag [0:N-1];

    reg [ADDR_W-1:0] load_idx;
    reg [ADDR_W-1:0] stage_idx;
    reg [ADDR_W-1:0] block_idx;
    reg [ADDR_W-1:0] j_idx;

    reg mode_run;
    reg done_r;
    assign done = done_r;

    wire [ADDR_W-1:0] load_bitrev;

    ifft16_bitrev_index #(
        .ADDR_W(ADDR_W)
    ) u_bitrev_index (
        .idx_in (load_idx),
        .idx_out(load_bitrev)
    );

    wire [ADDR_W-1:0] p_idx;
    wire [ADDR_W-1:0] q_idx;
    wire [ADDR_W-1:0] tw_idx;
    wire [ADDR_W:0]   half_size;
    wire [ADDR_W:0]   m_size;
    wire              last_j;
    wire              last_block;
    wire              last_stage;

    ifft16_stage_addr_gen #(
        .N(N),
        .ADDR_W(ADDR_W)
    ) u_stage_addr_gen (
        .stage     (stage_idx),
        .block_idx (block_idx),
        .j_idx     (j_idx),
        .p_idx     (p_idx),
        .q_idx     (q_idx),
        .tw_idx    (tw_idx),
        .half_size (half_size),
        .m_size    (m_size),
        .last_j    (last_j),
        .last_block(last_block),
        .last_stage(last_stage)
    );

    wire signed [COEFF_W-1:0] tw_cos;
    wire signed [COEFF_W-1:0] tw_sin;

    ifft16_twiddle_rom #(
        .COEFF_W(COEFF_W),
        .ADDR_W (ADDR_W)
    ) u_twiddle_rom (
        .tw_idx (tw_idx),
        .mode   (mode_run),
        .tw_cos (tw_cos),
        .tw_sin (tw_sin)
    );

    wire signed [OUT_W-1:0] bfly_p_real;
    wire signed [OUT_W-1:0] bfly_p_imag;
    wire signed [OUT_W-1:0] bfly_q_real;
    wire signed [OUT_W-1:0] bfly_q_imag;

    ifft16_butterfly #(
        .DATA_W (OUT_W),
        .COEFF_W(COEFF_W)
    ) u_butterfly (
        .xp_real   (mem_real[p_idx]),
        .xp_imag   (mem_imag[p_idx]),
        .xq_real   (mem_real[q_idx]),
        .xq_imag   (mem_imag[q_idx]),
        .tw_cos    (tw_cos),
        .tw_sin    (tw_sin),
        .yp_real   (bfly_p_real),
        .yp_imag   (bfly_p_imag),
        .yq_real   (bfly_q_real),
        .yq_imag   (bfly_q_imag)
    );

    genvar gout;
    generate
        for (gout = 0; gout < N; gout = gout + 1) begin : GEN_OUTPUT_SCALE
            ifft16_output_scaler #(
                .DATA_W(OUT_W),
                .SHIFT (GAIN_W)
            ) u_scale_real (
                .in_val  (mem_real[gout]),
                .scale_en(mode_run),
                .out_val (data_real_out[gout])
            );

            ifft16_output_scaler #(
                .DATA_W(OUT_W),
                .SHIFT (GAIN_W)
            ) u_scale_imag (
                .in_val  (mem_imag[gout]),
                .scale_en(mode_run),
                .out_val (data_imag_out[gout])
            );
        end
    endgenerate

    integer i;

    always @(posedge clk) begin
        if (rst) begin
            state     <= ST_IDLE;
            load_idx  <= {ADDR_W{1'b0}};
            stage_idx <= {ADDR_W{1'b0}};
            block_idx <= {ADDR_W{1'b0}};
            j_idx     <= {ADDR_W{1'b0}};
            mode_run  <= 1'b1;
            done_r    <= 1'b0;

            for (i = 0; i < N; i = i + 1) begin
                mem_real[i] <= {OUT_W{1'b0}};
                mem_imag[i] <= {OUT_W{1'b0}};
            end
        end else begin
            case (state)
                ST_IDLE: begin
                    done_r <= 1'b0;
                    if (start) begin
                        mode_run  <= mode;
                        load_idx  <= {ADDR_W{1'b0}};
                        stage_idx <= {ADDR_W{1'b0}};
                        block_idx <= {ADDR_W{1'b0}};
                        j_idx     <= {ADDR_W{1'b0}};
                        state     <= ST_LOAD;
                    end
                end

                ST_LOAD: begin
                    done_r <= 1'b0;

                    mem_real[load_bitrev] <= data_real_in[load_idx];
                    mem_imag[load_bitrev] <= data_imag_in[load_idx];

                    if ({1'b0, load_idx} == (N - 1)) begin
                        load_idx  <= {ADDR_W{1'b0}};
                        stage_idx <= {ADDR_W{1'b0}};
                        block_idx <= {ADDR_W{1'b0}};
                        j_idx     <= {ADDR_W{1'b0}};
                        state     <= ST_RUN;
                    end else begin
                        load_idx <= load_idx + {{(ADDR_W-1){1'b0}}, 1'b1};
                    end
                end

                ST_RUN: begin
                    mem_real[p_idx] <= bfly_p_real;
                    mem_imag[p_idx] <= bfly_p_imag;
                    mem_real[q_idx] <= bfly_q_real;
                    mem_imag[q_idx] <= bfly_q_imag;

                    if (last_j && last_block && last_stage) begin
                        done_r <= 1'b1;
                        state  <= ST_DONE;
                    end else begin
                        done_r <= 1'b0;

                        if (last_j) begin
                            j_idx <= {ADDR_W{1'b0}};

                            if (last_block) begin
                                block_idx <= {ADDR_W{1'b0}};
                                stage_idx <= stage_idx + {{(ADDR_W-1){1'b0}}, 1'b1};
                            end else begin
                                block_idx <= block_idx + m_size[ADDR_W-1:0];
                            end
                        end else begin
                            j_idx <= j_idx + {{(ADDR_W-1){1'b0}}, 1'b1};
                        end
                    end
                end

                ST_DONE: begin
                    done_r <= 1'b1;
                    if (start) begin
                        done_r    <= 1'b0;
                        mode_run  <= mode;
                        load_idx  <= {ADDR_W{1'b0}};
                        stage_idx <= {ADDR_W{1'b0}};
                        block_idx <= {ADDR_W{1'b0}};
                        j_idx     <= {ADDR_W{1'b0}};
                        state     <= ST_LOAD;
                    end
                end

                default: begin
                    state  <= ST_IDLE;
                    done_r <= 1'b0;
                end
            endcase
        end
    end

endmodule