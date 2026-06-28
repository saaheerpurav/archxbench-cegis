`timescale 1ns/1ps

module fft16_bit_reverse_loader #(
    parameter N      = 16,
    parameter DATA_W = 12,
    parameter OUT_W  = 16
) (
    input  signed [DATA_W-1:0] data_real_in [0:N-1],
    input  signed [DATA_W-1:0] data_imag_in [0:N-1],
    output signed [OUT_W-1:0]  load_real    [0:N-1],
    output signed [OUT_W-1:0]  load_imag    [0:N-1]
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

    localparam ADDR_W = (N <= 2) ? 1 : clog2(N);

    function integer bit_reverse_index;
        input integer idx;
        integer b;
        begin
            bit_reverse_index = 0;
            for (b = 0; b < ADDR_W; b = b + 1) begin
                bit_reverse_index = (bit_reverse_index << 1) | ((idx >> b) & 1);
            end
        end
    endfunction

    genvar gi;
    generate
        for (gi = 0; gi < N; gi = gi + 1) begin : g_bitrev_load
            assign load_real[bit_reverse_index(gi)] = data_real_in[gi];
            assign load_imag[bit_reverse_index(gi)] = data_imag_in[gi];
        end
    endgenerate

endmodule