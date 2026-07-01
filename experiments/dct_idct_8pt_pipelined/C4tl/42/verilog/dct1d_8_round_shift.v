`timescale 1ns/1ps

module dct1d_8_round_shift #(
    parameter IN_W  = 32,
    parameter SHIFT = 14
) (
    input  signed [IN_W-1:0] in_value,
    output signed [IN_W-1:0] out_value
);

    generate
        if (SHIFT == 0) begin : gen_no_shift
            assign out_value = in_value;
        end else begin : gen_round_shift
            localparam signed [IN_W-1:0] POS_BIAS = {{(IN_W-SHIFT){1'b0}}, 1'b1, {(SHIFT-1){1'b0}}};
            localparam signed [IN_W-1:0] NEG_BIAS = POS_BIAS - {{(IN_W-1){1'b0}}, 1'b1};

            wire signed [IN_W-1:0] bias;
            wire signed [IN_W-1:0] biased;

            assign bias      = in_value[IN_W-1] ? NEG_BIAS : POS_BIAS;
            assign biased    = in_value + bias;
            assign out_value = biased >>> SHIFT;
        end
    endgenerate

endmodule