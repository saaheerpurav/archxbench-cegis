`timescale 1ns/1ps

module conv2d_output_saturate #(
    parameter ACC_W = 32,
    parameter OUT_W = 12
) (
    input  signed [ACC_W-1:0] acc_in,
    output reg    [OUT_W-1:0] pixel_out
);

generate
    if (OUT_W < ACC_W) begin : gen_output_narrower_than_acc
        always @* begin
            if (acc_in[ACC_W-1]) begin
                pixel_out = {OUT_W{1'b0}};
            end else if (|acc_in[ACC_W-1:OUT_W]) begin
                pixel_out = {OUT_W{1'b1}};
            end else begin
                pixel_out = acc_in[OUT_W-1:0];
            end
        end
    end else if (OUT_W == ACC_W) begin : gen_output_same_as_acc
        always @* begin
            if (acc_in[ACC_W-1]) begin
                pixel_out = {OUT_W{1'b0}};
            end else begin
                pixel_out = acc_in;
            end
        end
    end else begin : gen_output_wider_than_acc
        always @* begin
            if (acc_in[ACC_W-1]) begin
                pixel_out = {OUT_W{1'b0}};
            end else begin
                pixel_out = {{(OUT_W-ACC_W){1'b0}}, acc_in};
            end
        end
    end
endgenerate

endmodule