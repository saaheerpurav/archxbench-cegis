`timescale 1ns/1ps

module nr_update_step #(
    parameter WIDTH = 16,
    parameter FRAC = 8,
    parameter EXT_WIDTH = (WIDTH * 4) + 8
)(
    input  signed [WIDTH-1:0]     x_current,
    input  signed [EXT_WIDTH-1:0] p,
    input  signed [EXT_WIDTH-1:0] p_prime,
    output signed [WIDTH-1:0]     x_next,
    output signed [WIDTH-1:0]     step,
    output                        derivative_zero
);

    localparam WIDE_WIDTH = 2 * EXT_WIDTH;

    localparam signed [WIDTH-1:0] MAX_POS = {1'b0, {(WIDTH-1){1'b1}}};
    localparam signed [WIDTH-1:0] MIN_NEG = {1'b1, {(WIDTH-1){1'b0}}};

    assign derivative_zero = (p_prime == 0);

    function signed [WIDTH-1:0] saturate_wide;
        input signed [WIDE_WIDTH-1:0] v;
        reg signed [WIDE_WIDTH-1:0] max_v;
        reg signed [WIDE_WIDTH-1:0] min_v;
        begin
            max_v = {{(WIDE_WIDTH-WIDTH){MAX_POS[WIDTH-1]}}, MAX_POS};
            min_v = {{(WIDE_WIDTH-WIDTH){MIN_NEG[WIDTH-1]}}, MIN_NEG};

            if (v > max_v)
                saturate_wide = MAX_POS;
            else if (v < min_v)
                saturate_wide = MIN_NEG;
            else
                saturate_wide = v[WIDTH-1:0];
        end
    endfunction

    function signed [WIDE_WIDTH-1:0] fixed_div_step_wide;
        input signed [EXT_WIDTH-1:0] numer;
        input signed [EXT_WIDTH-1:0] denom;
        reg signed [WIDE_WIDTH-1:0] scaled_num;
        reg signed [WIDE_WIDTH-1:0] denom_wide;
        begin
            if (denom == 0) begin
                fixed_div_step_wide = {WIDE_WIDTH{1'b0}};
            end else begin
                scaled_num = {{EXT_WIDTH{numer[EXT_WIDTH-1]}}, numer};
                scaled_num = scaled_num << FRAC;
                denom_wide = {{EXT_WIDTH{denom[EXT_WIDTH-1]}}, denom};
                fixed_div_step_wide = scaled_num / denom_wide;
            end
        end
    endfunction

    wire signed [WIDE_WIDTH-1:0] raw_step_wide;
    wire signed [WIDE_WIDTH-1:0] x_wide;
    wire signed [WIDE_WIDTH-1:0] next_wide;

    assign raw_step_wide = fixed_div_step_wide(p, p_prime);
    assign x_wide = {{(WIDE_WIDTH-WIDTH){x_current[WIDTH-1]}}, x_current};
    assign next_wide = x_wide - raw_step_wide;

    assign step = derivative_zero ? {WIDTH{1'b0}} : saturate_wide(raw_step_wide);
    assign x_next = derivative_zero ? x_current : saturate_wide(next_wide);

endmodule