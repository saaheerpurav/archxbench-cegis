`timescale 1ns/1ps

module dct1d_8_round_saturate #(
    parameter IN_W   = 32,
    parameter OUT_W  = 18,
    parameter FRAC_W = 14
) (
    input  signed [IN_W-1:0]  in_val,
    output reg signed [OUT_W-1:0] out_val
);
    localparam ADD_W = IN_W + 1;

    localparam signed [OUT_W-1:0] MAX_OUT = {1'b0, {(OUT_W-1){1'b1}}};
    localparam signed [OUT_W-1:0] MIN_OUT = {1'b1, {(OUT_W-1){1'b0}}};

    wire signed [ADD_W-1:0] in_ext = {in_val[IN_W-1], in_val};

    wire signed [ADD_W-1:0] pos_bias =
        (FRAC_W == 0) ? {ADD_W{1'b0}} :
        $signed({{(ADD_W-FRAC_W){1'b0}}, 1'b1, {(FRAC_W-1){1'b0}}});

    wire signed [ADD_W-1:0] neg_bias =
        (FRAC_W == 0) ? {ADD_W{1'b0}} :
        $signed({{(ADD_W-FRAC_W+1){1'b0}}, {(FRAC_W-1){1'b1}}});

    wire signed [ADD_W-1:0] rounded =
        in_ext + (in_val[IN_W-1] ? neg_bias : pos_bias);

    wire signed [ADD_W-1:0] shifted = rounded >>> FRAC_W;

    wire signed [ADD_W-1:0] max_ext =
        {{(ADD_W-OUT_W){MAX_OUT[OUT_W-1]}}, MAX_OUT};

    wire signed [ADD_W-1:0] min_ext =
        {{(ADD_W-OUT_W){MIN_OUT[OUT_W-1]}}, MIN_OUT};

    always @* begin
        if (shifted > max_ext)
            out_val = MAX_OUT;
        else if (shifted < min_ext)
            out_val = MIN_OUT;
        else
            out_val = shifted[OUT_W-1:0];
    end
endmodule