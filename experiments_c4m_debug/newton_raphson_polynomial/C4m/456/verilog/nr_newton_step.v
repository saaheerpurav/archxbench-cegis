`timescale 1ns/1ps

module nr_newton_step #(
    parameter WIDTH = 16,
    parameter FRAC  = 8,
    parameter EXT   = WIDTH * 4
)(
    input  signed [WIDTH-1:0] x,
    input  signed [EXT-1:0]   p,
    input  signed [EXT-1:0]   dp,
    output signed [WIDTH-1:0] x_next
);

    wire signed [EXT-1:0] x_ext;
    wire signed [(2*EXT)-1:0] p_wide;
    wire signed [(2*EXT)-1:0] numerator;
    wire signed [(2*EXT)-1:0] quotient_wide;
    wire signed [EXT-1:0] delta;
    wire signed [EXT-1:0] raw_next;

    assign x_ext = {{(EXT-WIDTH){x[WIDTH-1]}}, x};

    // Scale p before division so p/dp remains in the same Q format as x.
    assign p_wide = {{EXT{p[EXT-1]}}, p};
    assign numerator = p_wide << FRAC;

    assign quotient_wide = (dp == {EXT{1'b0}}) ? {(2*EXT){1'b0}} : (numerator / dp);

    assign delta = saturate_to_ext(quotient_wide);
    assign raw_next = x_ext - delta;

    assign x_next = saturate_to_width(raw_next);

    function signed [EXT-1:0] saturate_to_ext;
        input signed [(2*EXT)-1:0] value;
        reg signed [(2*EXT)-1:0] max_value;
        reg signed [(2*EXT)-1:0] min_value;
        begin
            max_value = {{EXT{1'b0}}, {1'b0, {(EXT-1){1'b1}}}};
            min_value = {{EXT{1'b1}}, {1'b1, {(EXT-1){1'b0}}}};

            if (value > max_value)
                saturate_to_ext = {1'b0, {(EXT-1){1'b1}}};
            else if (value < min_value)
                saturate_to_ext = {1'b1, {(EXT-1){1'b0}}};
            else
                saturate_to_ext = value[EXT-1:0];
        end
    endfunction

    function signed [WIDTH-1:0] saturate_to_width;
        input signed [EXT-1:0] value;
        reg signed [EXT-1:0] max_value;
        reg signed [EXT-1:0] min_value;
        begin
            max_value = {{(EXT-WIDTH){1'b0}}, {1'b0, {(WIDTH-1){1'b1}}}};
            min_value = {{(EXT-WIDTH){1'b1}}, {1'b1, {(WIDTH-1){1'b0}}}};

            if (value > max_value)
                saturate_to_width = {1'b0, {(WIDTH-1){1'b1}}};
            else if (value < min_value)
                saturate_to_width = {1'b1, {(WIDTH-1){1'b0}}};
            else
                saturate_to_width = value[WIDTH-1:0];
        end
    endfunction

endmodule