`timescale 1ns/1ps

module gs2x2_reciprocal #(
    parameter DATA_WIDTH = 32,
    parameter FRAC = 16
)(
    input signed [DATA_WIDTH-1:0] value,
    output reg signed [DATA_WIDTH-1:0] reciprocal
);

    reg signed [(2*DATA_WIDTH)-1:0] numerator;
    reg signed [(2*DATA_WIDTH)-1:0] divisor;
    reg signed [(2*DATA_WIDTH)-1:0] quotient;

    localparam signed [DATA_WIDTH-1:0] MAX_POS = {1'b0, {(DATA_WIDTH-1){1'b1}}};
    localparam signed [DATA_WIDTH-1:0] MIN_NEG = {1'b1, {(DATA_WIDTH-1){1'b0}}};

    always @(*) begin
        numerator = {(2*DATA_WIDTH){1'b0}};
        numerator[2*FRAC] = 1'b1;

        divisor = {{DATA_WIDTH{value[DATA_WIDTH-1]}}, value};

        if (value == {DATA_WIDTH{1'b0}}) begin
            reciprocal = {DATA_WIDTH{1'b0}};
        end else begin
            quotient = numerator / divisor;

            if (quotient > MAX_POS)
                reciprocal = MAX_POS;
            else if (quotient < MIN_NEG)
                reciprocal = MIN_NEG;
            else
                reciprocal = quotient[DATA_WIDTH-1:0];
        end
    end

endmodule