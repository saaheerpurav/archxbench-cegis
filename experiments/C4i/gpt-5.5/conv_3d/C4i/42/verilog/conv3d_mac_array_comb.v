`timescale 1ns/1ps

module conv3d_mac_array_comb #(
    parameter NUM_TAPS = 27,
    parameter DATA_W   = 8,
    parameter OUT_W    = 12,
    parameter ACC_W    = (2*DATA_W + 16)
) (
    input  [NUM_TAPS*DATA_W-1:0] window_flat,
    input  [NUM_TAPS*DATA_W-1:0] kernel_flat,
    input                        enable,
    output [OUT_W-1:0]           result
);

    integer i;

    reg [DATA_W-1:0] a;
    reg [DATA_W-1:0] b;
    reg [ACC_W-1:0]  acc;

    /*
     * Unsigned DATA_W x DATA_W multiply, returned in ACC_W bits.
     * Implemented with shift-add to avoid simulator-dependent or lint-sensitive
     * multiply expression sizing.
     */
    function [ACC_W-1:0] mul_u_to_acc;
        input [DATA_W-1:0] x;
        input [DATA_W-1:0] y;

        integer k;
        integer m;
        reg [ACC_W-1:0] x_ext;
        begin
            x_ext       = {ACC_W{1'b0}};
            mul_u_to_acc = {ACC_W{1'b0}};

            for (m = 0; m < DATA_W; m = m + 1) begin
                if (m < ACC_W) begin
                    x_ext[m] = x[m];
                end
            end

            for (k = 0; k < DATA_W; k = k + 1) begin
                if (y[k]) begin
                    mul_u_to_acc = mul_u_to_acc + (x_ext << k);
                end
            end
        end
    endfunction

    always @* begin
        acc = {ACC_W{1'b0}};

        if (enable) begin
            for (i = 0; i < NUM_TAPS; i = i + 1) begin
                a = window_flat[i*DATA_W +: DATA_W];
                b = kernel_flat[i*DATA_W +: DATA_W];

                acc = acc + mul_u_to_acc(a, b);
            end
        end
    end

    generate
        if (OUT_W <= ACC_W) begin : gen_result_truncate
            assign result = acc[OUT_W-1:0];
        end else begin : gen_result_extend
            assign result = {{(OUT_W-ACC_W){1'b0}}, acc};
        end
    endgenerate

endmodule