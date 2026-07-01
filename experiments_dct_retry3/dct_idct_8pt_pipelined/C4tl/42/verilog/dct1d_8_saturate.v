`timescale 1ns/1ps

module dct1d_8_saturate #(
    parameter IN_W = 48,
    parameter OUT_W = 18
) (
    input signed [IN_W-1:0] din,
    output reg signed [OUT_W-1:0] dout
);

    localparam signed [IN_W-1:0] MAX_OUT = (48'sd1 <<< (OUT_W-1)) - 48'sd1;
    localparam signed [IN_W-1:0] MIN_OUT = -(48'sd1 <<< (OUT_W-1));

    always @* begin
        if (din > MAX_OUT) begin
            dout = {1'b0, {OUT_W-1{1'b1}}};
        end else if (din < MIN_OUT) begin
            dout = {1'b1, {OUT_W-1{1'b0}}};
        end else begin
            dout = din[OUT_W-1:0];
        end
    end

endmodule