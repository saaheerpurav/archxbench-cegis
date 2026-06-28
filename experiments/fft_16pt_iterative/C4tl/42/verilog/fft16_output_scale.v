`timescale 1ns/1ps

module fft16_output_scale #(
    parameter N = 16,
    parameter OUT_W = 16
) (
    input  mode,
    input  signed [OUT_W-1:0] data_real_mem [0:N-1],
    input  signed [OUT_W-1:0] data_imag_mem [0:N-1],
    output signed [OUT_W-1:0] data_real_out [0:N-1],
    output signed [OUT_W-1:0] data_imag_out [0:N-1]
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

    localparam integer SCALE_SHIFT = clog2(N);

    genvar gi;
    generate
        for (gi = 0; gi < N; gi = gi + 1) begin : g_output_scale
            wire signed [OUT_W-1:0] real_scaled;
            wire signed [OUT_W-1:0] imag_scaled;

            assign real_scaled = data_real_mem[gi] >>> SCALE_SHIFT;
            assign imag_scaled = data_imag_mem[gi] >>> SCALE_SHIFT;

            assign data_real_out[gi] = mode ? real_scaled : data_real_mem[gi];
            assign data_imag_out[gi] = mode ? imag_scaled : data_imag_mem[gi];
        end
    endgenerate

endmodule