`timescale 1ns/1ps

module fp_mult_normalize (
    input [47:0] product,
    input signed [9:0] exp_in,
    output reg [23:0] sig_norm,
    output reg guard_bit,
    output reg round_bit,
    output reg sticky_bit,
    output reg signed [9:0] exp_norm
);

integer i;
integer lead_pos;
integer shift_amt;
reg [47:0] product_shifted;
reg found;

always @* begin
    sig_norm = 24'b0;
    guard_bit = 1'b0;
    round_bit = 1'b0;
    sticky_bit = 1'b0;
    exp_norm = exp_in;

    lead_pos = 0;
    shift_amt = 0;
    product_shifted = 48'b0;
    found = 1'b0;

    if (product != 48'b0) begin
        if (product[47]) begin
            sig_norm = product[47:24];
            guard_bit = product[23];
            round_bit = product[22];
            sticky_bit = |product[21:0];
            exp_norm = exp_in + 10'sd1;
        end else begin
            for (i = 46; i >= 0; i = i - 1) begin
                if (!found && product[i]) begin
                    lead_pos = i;
                    found = 1'b1;
                end
            end

            shift_amt = 46 - lead_pos;
            product_shifted = product << shift_amt;

            sig_norm = product_shifted[46:23];
            guard_bit = product_shifted[22];
            round_bit = product_shifted[21];
            sticky_bit = |product_shifted[20:0];
            exp_norm = exp_in - shift_amt[9:0];
        end
    end
end

endmodule