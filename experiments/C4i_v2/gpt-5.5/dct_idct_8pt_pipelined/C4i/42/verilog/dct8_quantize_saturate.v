`timescale 1ns/1ps

module dct8_quantize_saturate #(
    parameter IN_W   = 31,
    parameter OUT_W  = 18,
    parameter FRAC_W = 14
) (
    input  signed [IN_W-1:0]  value_in,
    output signed [OUT_W-1:0] value_out
);

    /*
     * Combinational fixed-point rounding, scaling, and saturation.
     *
     * Operation:
     *   rounded = value_in + 2^(FRAC_W-1)
     *   shifted = rounded >>> FRAC_W
     *   value_out = saturate_signed_OUT_W(shifted)
     *
     * One guard bit is used during the rounding add so that values near the
     * IN_W limits do not wrap before the saturation comparison.
     */

    localparam EXT_W = IN_W + 1;

    localparam signed [OUT_W-1:0] OUT_MAX =
        {1'b0, {(OUT_W-1){1'b1}}};

    localparam signed [OUT_W-1:0] OUT_MIN =
        {1'b1, {(OUT_W-1){1'b0}}};

    wire signed [EXT_W-1:0] value_ext;
    assign value_ext = {value_in[IN_W-1], value_in};

    wire signed [EXT_W-1:0] round_bias;

generate
    if (FRAC_W == 0) begin : gen_no_round
        assign round_bias = {EXT_W{1'b0}};
    end else begin : gen_round
        assign round_bias = $signed({{(EXT_W-1){1'b0}}, 1'b1} << (FRAC_W-1));
    end
endgenerate

    wire signed [EXT_W-1:0] rounded;
    wire signed [EXT_W-1:0] shifted;

    assign rounded = value_ext + round_bias;
    assign shifted = rounded >>> FRAC_W;

    wire signed [EXT_W-1:0] max_ext;
    wire signed [EXT_W-1:0] min_ext;

    assign max_ext = {{(EXT_W-OUT_W){OUT_MAX[OUT_W-1]}}, OUT_MAX};
    assign min_ext = {{(EXT_W-OUT_W){OUT_MIN[OUT_W-1]}}, OUT_MIN};

    assign value_out = (shifted > max_ext) ? OUT_MAX :
                       (shifted < min_ext) ? OUT_MIN :
                       shifted[OUT_W-1:0];

endmodule