`timescale 1ns/1ps

module fft16_bit_reverse_loader #(
    parameter N = 16,
    parameter DATA_W = 12,
    parameter OUT_W = 16
) (
    input signed [DATA_W-1:0] data_real_in [0:N-1],
    input signed [DATA_W-1:0] data_imag_in [0:N-1],
    output signed [OUT_W-1:0] data_real_out [0:N-1],
    output signed [OUT_W-1:0] data_imag_out [0:N-1]
);
    localparam ADDR_W = $clog2(N);

    function automatic integer bit_reverse;
        input integer idx;
        integer b;
        begin
            bit_reverse = 0;
            for (b = 0; b < ADDR_W; b = b + 1) begin
                bit_reverse = (bit_reverse << 1) | ((idx >> b) & 1);
            end
        end
    endfunction

    genvar i;
    generate
        for (i = 0; i < N; i = i + 1) begin : g_bit_reverse_load
            assign data_real_out[bit_reverse(i)] =
                {{(OUT_W-DATA_W){data_real_in[i][DATA_W-1]}}, data_real_in[i]};

            assign data_imag_out[bit_reverse(i)] =
                {{(OUT_W-DATA_W){data_imag_in[i][DATA_W-1]}}, data_imag_in[i]};
        end
    endgenerate
endmodule