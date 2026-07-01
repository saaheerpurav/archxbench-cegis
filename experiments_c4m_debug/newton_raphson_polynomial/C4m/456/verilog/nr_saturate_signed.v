`timescale 1ns/1ps

module nr_saturate_signed #(
    parameter IN_WIDTH  = 64,
    parameter OUT_WIDTH = 16
)(
    input  signed [IN_WIDTH-1:0]  in_value,
    output reg signed [OUT_WIDTH-1:0] out_value
);

generate
    if (IN_WIDTH > OUT_WIDTH) begin : gen_saturating_narrow
        localparam signed [IN_WIDTH-1:0] MAX_POS =
            {{(IN_WIDTH-OUT_WIDTH){1'b0}}, 1'b0, {(OUT_WIDTH-1){1'b1}}};

        localparam signed [IN_WIDTH-1:0] MIN_NEG =
            {{(IN_WIDTH-OUT_WIDTH){1'b1}}, 1'b1, {(OUT_WIDTH-1){1'b0}}};

        always @(*) begin
            if (in_value > MAX_POS) begin
                out_value = {1'b0, {(OUT_WIDTH-1){1'b1}}};
            end else if (in_value < MIN_NEG) begin
                out_value = {1'b1, {(OUT_WIDTH-1){1'b0}}};
            end else begin
                out_value = in_value[OUT_WIDTH-1:0];
            end
        end
    end else begin : gen_no_saturation_needed
        always @(*) begin
            out_value = in_value[OUT_WIDTH-1:0];
        end
    end
endgenerate

endmodule