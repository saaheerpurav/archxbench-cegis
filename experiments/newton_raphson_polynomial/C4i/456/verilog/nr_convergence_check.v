`timescale 1ns/1ps

module nr_convergence_check #(
    parameter WIDTH = 16,
    parameter signed [WIDTH-1:0] TOLERANCE = 8
)(
    input signed [WIDTH-1:0] delta,
    input signed [WIDTH-1:0] poly,
    input derivative_zero,
    output converged
);

    function signed [WIDTH-1:0] abs_signed;
        input signed [WIDTH-1:0] value;
        begin
            if (value == {1'b1, {(WIDTH-1){1'b0}}})
                abs_signed = {1'b0, {(WIDTH-1){1'b1}}};
            else if (value < 0)
                abs_signed = -value;
            else
                abs_signed = value;
        end
    endfunction

    wire signed [WIDTH-1:0] abs_delta;
    wire signed [WIDTH-1:0] abs_poly;

    assign abs_delta = abs_signed(delta);
    assign abs_poly  = abs_signed(poly);

    assign converged = derivative_zero
                     ? (abs_poly <= TOLERANCE)
                     : (abs_delta <= {{(WIDTH-1){1'b0}}, 1'b1});

endmodule