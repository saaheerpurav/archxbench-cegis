`timescale 1ns/1ps

module fp_normalize_round (
    input sign_in,
    input [7:0] exp_in,
    input [27:0] mant_in,
    input is_zero,
    output reg [31:0] result
);

reg [27:0] mant_norm;
reg signed [9:0] exp_norm;
reg [27:0] mant_pack;
reg [23:0] mant_keep;
reg guard_bit;
reg round_bit;
reg sticky_bit;
reg round_up;
reg [24:0] mant_rounded;
reg [7:0] exp_out;
reg [22:0] frac_out;
integer i;
integer shift_amt;

always @* begin
    result = 32'd0;

    mant_norm = mant_in;
    exp_norm = {2'b00, exp_in};

    mant_pack = 28'd0;
    mant_keep = 24'd0;
    guard_bit = 1'b0;
    round_bit = 1'b0;
    sticky_bit = 1'b0;
    round_up = 1'b0;
    mant_rounded = 25'd0;
    exp_out = 8'd0;
    frac_out = 23'd0;
    shift_amt = 0;

    if (is_zero || mant_in == 28'd0) begin
        result = {sign_in, 31'd0};
    end else begin
        if (mant_norm[27]) begin
            mant_norm = {1'b0, mant_norm[27:1]};
            mant_norm[0] = mant_in[1] | mant_in[0];
            exp_norm = exp_norm + 10'sd1;
        end else begin
            for (i = 0; i < 27; i = i + 1) begin
                if (!mant_norm[26] && exp_norm > 0) begin
                    mant_norm = mant_norm << 1;
                    exp_norm = exp_norm - 10'sd1;
                end
            end
        end

        if (exp_norm >= 10'sd255) begin
            result = {sign_in, 8'hff, 23'd0};
        end else begin
            mant_pack = mant_norm;

            if (exp_norm <= 0) begin
                shift_amt = 1 - exp_norm;

                for (i = 0; i < 28; i = i + 1) begin
                    if (i < shift_amt) begin
                        mant_pack = {1'b0, mant_pack[27:1]};
                        mant_pack[0] = mant_pack[0] | mant_pack[1];
                    end
                end

                exp_out = 8'd0;
            end else begin
                exp_out = exp_norm[7:0];
            end

            mant_keep = mant_pack[26:3];
            guard_bit = mant_pack[2];
            round_bit = mant_pack[1];
            sticky_bit = mant_pack[0];

            round_up = guard_bit && (round_bit || sticky_bit || mant_keep[0]);
            mant_rounded = {1'b0, mant_keep} + {24'd0, round_up};

            if (mant_rounded[24]) begin
                if (exp_out == 8'd254) begin
                    result = {sign_in, 8'hff, 23'd0};
                end else if (exp_out == 8'd0) begin
                    result = {sign_in, 8'd1, 23'd0};
                end else begin
                    result = {sign_in, exp_out + 8'd1, mant_rounded[23:1]};
                end
            end else begin
                if (exp_out == 8'd0) begin
                    frac_out = mant_rounded[22:0];
                end else begin
                    frac_out = mant_rounded[22:0];
                end

                if (mant_rounded[23:0] == 24'd0) begin
                    result = {sign_in, 31'd0};
                end else begin
                    result = {sign_in, exp_out, frac_out};
                end
            end
        end
    end
end

endmodule