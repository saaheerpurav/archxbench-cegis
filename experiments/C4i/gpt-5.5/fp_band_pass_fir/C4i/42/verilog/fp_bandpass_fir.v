`timescale 1ns/1ps

module fp_bandpass_fir #(
    parameter TAP_CNT    = 63,
    parameter PIPE_DEPTH = 2
) (
    input                   clk,
    input                   rst,
    input                   valid_in,
    input       [31:0]      data_in,
    output                  valid_out,
    output      [31:0]      data_out
);

    /*
     * Coefficient memory intentionally exposed as an internal array so the
     * supplied testbench can preload coefficients with:
     *
     *     dut.coeffs[j] = coeffs[j];
     *
     * Reset does NOT clear coefficients.
     */
    reg [31:0] coeffs [0:TAP_CNT-1];

    localparam RESULT_LATENCY = TAP_CNT - 1;

    reg  [TAP_CNT*32-1:0] sample_regs_flat;
    wire [TAP_CNT*32-1:0] next_sample_regs_flat;
    wire [TAP_CNT*32-1:0] coeffs_flat;
    wire [TAP_CNT*32-1:0] products_flat;
    wire [31:0]           fir_result_comb;

    reg  [31:0] result_pipe [0:RESULT_LATENCY];
    reg         valid_pipe  [0:RESULT_LATENCY];

    integer i;

    genvar gi;
    generate
        for (gi = 0; gi < TAP_CNT; gi = gi + 1) begin : GEN_COEFF_FLATTEN
            assign coeffs_flat[gi*32 +: 32] = coeffs[gi];
        end
    endgenerate

    fp_fir_sample_window_comb #(
        .TAP_CNT(TAP_CNT)
    ) u_sample_window (
        .samples_flat_in  (sample_regs_flat),
        .valid_in         (valid_in),
        .data_in          (data_in),
        .samples_flat_out (next_sample_regs_flat)
    );

    fp_fir_tap_products_comb #(
        .TAP_CNT(TAP_CNT)
    ) u_tap_products (
        .samples_flat  (next_sample_regs_flat),
        .coeffs_flat   (coeffs_flat),
        .products_flat (products_flat)
    );

    fp_fir_sum_tree_comb #(
        .TAP_CNT(TAP_CNT)
    ) u_sum_tree (
        .products_flat (products_flat),
        .sum_out       (fir_result_comb)
    );

    always @(posedge clk) begin
        if (rst) begin
            sample_regs_flat <= {TAP_CNT*32{1'b0}};
            for (i = 0; i <= RESULT_LATENCY; i = i + 1) begin
                result_pipe[i] <= 32'h00000000;
                valid_pipe[i]  <= 1'b0;
            end
        end else begin
            sample_regs_flat <= next_sample_regs_flat;

            result_pipe[0] <= fir_result_comb;
            valid_pipe[0]  <= valid_in;

            for (i = 1; i <= RESULT_LATENCY; i = i + 1) begin
                result_pipe[i] <= result_pipe[i-1];
                valid_pipe[i]  <= valid_pipe[i-1];
            end
        end
    end

    assign data_out  = result_pipe[RESULT_LATENCY];
    assign valid_out = valid_pipe[RESULT_LATENCY];

endmodule