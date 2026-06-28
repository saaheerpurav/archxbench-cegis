`timescale 1ns/1ps

module fp_normalize (
    input  [47:0] product,
    input  signed [12:0] exponent_sum,
    output reg [23:0] significand_norm,
    output reg signed [12:0] exponent_norm,
    output reg guard_bit,
    output reg round_bit,
    output reg sticky_bit
);

    integer i;

    reg found;
    reg [5:0] lead_pos;
    reg [5:0] shift_amt;
    reg [47:0] shifted_product;
    reg signed [12:0] shift_amt_signed;

    always @* begin
        significand_norm = 24'd0;
        exponent_norm     = exponent_sum;
        guard_bit         = 1'b0;
        round_bit         = 1'b0;
        sticky_bit        = 1'b0;

        found             = 1'b0;
        lead_pos          = 6'd0;
        shift_amt         = 6'd0;
        shifted_product   = 48'd0;
        shift_amt_signed  = 13'sd0;

        if (product == 48'd0) begin
            significand_norm = 24'd0;
            exponent_norm     = exponent_sum;
            guard_bit         = 1'b0;
            round_bit         = 1'b0;
            sticky_bit        = 1'b0;
        end else if (product[47]) begin
            /*
             * Product is in [2.0, 4.0).
             *
             * Normalize by selecting the leading 24 bits starting at bit 47
             * and incrementing the exponent.  The discarded bits below the
             * selected significand generate guard, round, and sticky.
             */
            significand_norm = product[47:24];
            exponent_norm     = exponent_sum + 13'sd1;
            guard_bit         = product[23];
            round_bit         = product[22];
            sticky_bit        = |product[21:0];
        end else begin
            /*
             * Product is below 2.0.  Locate the leading one below bit 47 and
             * shift left until it reaches bit 46, the normal hidden-bit
             * position for a 24-bit IEEE-754 significand.
             */
            for (i = 46; i >= 0; i = i - 1) begin
                if (!found && product[i]) begin
                    found    = 1'b1;
                    lead_pos = i[5:0];
                end
            end

            if (found) begin
                shift_amt        = 6'd46 - lead_pos;
                shift_amt_signed = $signed({7'd0, shift_amt});
                shifted_product  = product << shift_amt;

                significand_norm = shifted_product[46:23];
                exponent_norm     = exponent_sum - shift_amt_signed;
                guard_bit         = shifted_product[22];
                round_bit         = shifted_product[21];
                sticky_bit        = |shifted_product[20:0];
            end
        end
    end

endmodule