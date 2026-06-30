`timescale 1ns/1ps

module nr_newton_update #(
    parameter WIDTH = 16,
    parameter FRAC = 8
)(
    input  signed [WIDTH-1:0] x_current,
    input  signed [WIDTH-1:0] poly,
    input  signed [WIDTH-1:0] deriv,
    output signed [WIDTH-1:0] x_next,
    output signed [WIDTH-1:0] delta,
    output derivative_zero
);

    function signed [WIDTH-1:0] sat_signed;
        input signed [63:0] value;
        reg signed [63:0] max_val;
        reg signed [63:0] min_val;
        begin
            max_val = (64'sd1 << (WIDTH-1)) - 64'sd1;
            min_val = -(64'sd1 << (WIDTH-1));

            if (value > max_val)
                sat_signed = {1'b0, {(WIDTH-1){1'b1}}};
            else if (value < min_val)
                sat_signed = {1'b1, {(WIDTH-1){1'b0}}};
            else
                sat_signed = value[WIDTH-1:0];
        end
    endfunction

    function signed [63:0] abs64;
        input signed [63:0] value;
        begin
            abs64 = (value < 0) ? -value : value;
        end
    endfunction

    function signed [63:0] fixed_div_wide;
        input signed [WIDTH-1:0] numerator;
        input signed [WIDTH-1:0] denominator;
        reg signed [63:0] scaled_num;
        reg signed [63:0] denom_wide;
        reg signed [63:0] q_trunc;
        reg signed [63:0] q_adj;
        reg signed [63:0] err_trunc;
        reg signed [63:0] err_adj;
        begin
            if (denominator == {WIDTH{1'b0}}) begin
                fixed_div_wide = 64'sd0;
            end else begin
                scaled_num = $signed(numerator) * (64'sd1 << FRAC);
                denom_wide = $signed(denominator);
                q_trunc = scaled_num / denom_wide;

                if (scaled_num[63] ^ denom_wide[63])
                    q_adj = q_trunc - 64'sd1;
                else
                    q_adj = q_trunc + 64'sd1;

                err_trunc = abs64(scaled_num - (q_trunc * denom_wide));
                err_adj   = abs64(scaled_num - (q_adj   * denom_wide));

                if (err_adj < err_trunc)
                    fixed_div_wide = q_adj;
                else
                    fixed_div_wide = q_trunc;
            end
        end
    endfunction

    wire signed [63:0] raw_delta_wide;
    wire signed [63:0] next_wide;

    assign derivative_zero = (deriv == {WIDTH{1'b0}});
    assign raw_delta_wide = fixed_div_wide(poly, deriv);
    assign next_wide = $signed(x_current) - raw_delta_wide;

    assign delta = derivative_zero ? {WIDTH{1'b0}} : sat_signed(raw_delta_wide);
    assign x_next = derivative_zero ? x_current : sat_signed(next_wide);

endmodule