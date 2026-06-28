`timescale 1ns/1ps

module fp_highpass_fir #(
    parameter TAP_CNT    = 31,
    parameter PIPE_DEPTH = 2
) (
    input                   clk,
    input                   rst,
    input                   valid_in,
    input   [31:0]          data_in,
    output                  valid_out,
    output  [31:0]          data_out
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

    localparam LEVELS  = clog2(TAP_CNT);
    localparam PAD_CNT = (1 << LEVELS);
    localparam LATENCY = (TAP_CNT > 1) ? (TAP_CNT - 1) : 1;

    reg [31:0] coeffs [0:TAP_CNT-1];

    reg [31:0] sample_delay [0:TAP_CNT-2];
    reg [31:0] data_pipe    [0:LATENCY-1];
    reg        valid_pipe   [0:LATENCY-1];

    wire [31:0] gated_data_in;
    wire [31:0] tap_sample [0:TAP_CNT-1];
    wire [31:0] products   [0:TAP_CNT-1];

    wire [31:0] add_level [0:LEVELS][0:PAD_CNT-1];

    genvar gi, gl, gj;

    fp32_zero_mux u_input_zero_mux (
        .valid_in(valid_in),
        .data_in(data_in),
        .data_out(gated_data_in)
    );

    assign tap_sample[0] = gated_data_in;

    generate
        for (gi = 1; gi < TAP_CNT; gi = gi + 1) begin : GEN_TAPS
            assign tap_sample[gi] = sample_delay[gi-1];
        end
    endgenerate

    generate
        for (gi = 0; gi < TAP_CNT; gi = gi + 1) begin : GEN_MULTS
            fp32_mul u_mul (
                .a(tap_sample[gi]),
                .b(coeffs[gi]),
                .y(products[gi])
            );
        end
    endgenerate

    generate
        for (gi = 0; gi < PAD_CNT; gi = gi + 1) begin : GEN_LEVEL0
            if (gi < TAP_CNT) begin : GEN_REAL_PRODUCT
                assign add_level[0][gi] = products[gi];
            end else begin : GEN_PAD_ZERO
                assign add_level[0][gi] = 32'h00000000;
            end
        end
    endgenerate

    generate
        for (gl = 0; gl < LEVELS; gl = gl + 1) begin : GEN_ADD_LEVELS
            for (gj = 0; gj < (PAD_CNT >> (gl + 1)); gj = gj + 1) begin : GEN_ADDERS
                fp32_add u_add (
                    .a(add_level[gl][2*gj]),
                    .b(add_level[gl][2*gj+1]),
                    .y(add_level[gl+1][gj])
                );
            end

            for (gj = (PAD_CNT >> (gl + 1)); gj < PAD_CNT; gj = gj + 1) begin : GEN_UNUSED_LEVEL
                assign add_level[gl+1][gj] = 32'h00000000;
            end
        end
    endgenerate

    wire [31:0] fir_comb_sum;
    assign fir_comb_sum = add_level[LEVELS][0];

    integer si;
    integer pi;

    always @(posedge clk) begin
        if (rst) begin
            for (si = 0; si < TAP_CNT-1; si = si + 1) begin
                sample_delay[si] <= 32'h00000000;
            end
            for (pi = 0; pi < LATENCY; pi = pi + 1) begin
                data_pipe[pi]  <= 32'h00000000;
                valid_pipe[pi] <= 1'b0;
            end
        end else begin
            if (valid_in) begin
                if (TAP_CNT > 1) begin
                    sample_delay[0] <= data_in;
                    for (si = 1; si < TAP_CNT-1; si = si + 1) begin
                        sample_delay[si] <= sample_delay[si-1];
                    end
                end
            end

            data_pipe[0]  <= fir_comb_sum;
            valid_pipe[0] <= valid_in;

            for (pi = 1; pi < LATENCY; pi = pi + 1) begin
                data_pipe[pi]  <= data_pipe[pi-1];
                valid_pipe[pi] <= valid_pipe[pi-1];
            end
        end
    end

    assign data_out  = data_pipe[LATENCY-1];
    assign valid_out = valid_pipe[LATENCY-1];

endmodule