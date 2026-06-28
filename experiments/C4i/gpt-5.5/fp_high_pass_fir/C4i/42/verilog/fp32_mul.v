`timescale 1ns/1ps

module fp32_mul (
    input  [31:0] a,
    input  [31:0] b,
    output reg [31:0] y
);

    wire        sign_a = a[31];
    wire        sign_b = b[31];
    wire [7:0]  exp_a  = a[30:23];
    wire [7:0]  exp_b  = b[30:23];
    wire [22:0] frac_a = a[22:0];
    wire [22:0] frac_b = b[22:0];

    wire a_zero = (exp_a == 8'h00) && (frac_a == 23'h0);
    wire b_zero = (exp_b == 8'h00) && (frac_b == 23'h0);

    wire a_inf  = (exp_a == 8'hff) && (frac_a == 23'h0);
    wire b_inf  = (exp_b == 8'hff) && (frac_b == 23'h0);

    wire a_nan  = (exp_a == 8'hff) && (frac_a != 23'h0);
    wire b_nan  = (exp_b == 8'hff) && (frac_b != 23'h0);

    /*
     * Return OR of v[count-1:0].
     * If count <= 0, returns 0.
     * If count >= 48, returns OR of all bits.
     */
    function any_low_bits;
        input [47:0] v;
        input integer count;
        integer i;
        begin
            any_low_bits = 1'b0;
            if (count > 0) begin
                for (i = 0; i < 48; i = i + 1) begin
                    if (i < count)
                        any_low_bits = any_low_bits | v[i];
                end
            end
        end
    endfunction

    /*
     * Highest asserted bit index in a nonzero 48-bit value.
     */
    function integer msb_index;
        input [47:0] v;
        integer i;
        begin
            msb_index = 0;
            for (i = 0; i < 48; i = i + 1) begin
                if (v[i])
                    msb_index = i;
            end
        end
    endfunction

    reg        sign_y;

    reg [23:0] mant_a;
    reg [23:0] mant_b;

    integer exp_unb_a;
    integer exp_unb_b;
    integer exp_sum;

    reg [47:0] product;

    integer prod_msb;
    integer exp_norm;
    integer shift_norm;

    reg [23:0] mant_pre;
    reg        guard_bit;
    reg        sticky_bit;
    reg        round_inc;
    reg [24:0] rounded;

    integer exp_after_round;
    integer exp_field;

    integer scale_sub;
    integer shift_sub;

    reg [127:0] wide_product;
    reg [127:0] sub_pre;
    reg [127:0] sub_rounded;

    always @* begin
        sign_y = sign_a ^ sign_b;

        mant_a = 24'h0;
        mant_b = 24'h0;

        exp_unb_a = 0;
        exp_unb_b = 0;
        exp_sum   = 0;

        product = 48'h0;

        prod_msb       = 0;
        exp_norm       = 0;
        shift_norm     = 0;
        exp_after_round = 0;
        exp_field      = 0;

        mant_pre  = 24'h0;
        guard_bit = 1'b0;
        sticky_bit = 1'b0;
        round_inc = 1'b0;
        rounded   = 25'h0;

        scale_sub   = 0;
        shift_sub   = 0;
        wide_product = 128'h0;
        sub_pre      = 128'h0;
        sub_rounded  = 128'h0;

        y = 32'h00000000;

        /*
         * Special cases.
         */
        if (a_nan) begin
            y = {sign_a, 8'hff, 1'b1, frac_a[21:0]};
        end else if (b_nan) begin
            y = {sign_b, 8'hff, 1'b1, frac_b[21:0]};
        end else if ((a_inf && b_zero) || (b_inf && a_zero)) begin
            y = 32'h7fc00000;
        end else if (a_inf || b_inf) begin
            y = {sign_y, 8'hff, 23'h000000};
        end else if (a_zero || b_zero) begin
            y = {sign_y, 31'h00000000};
        end else begin
            /*
             * Build 24-bit significands and unbiased exponents.
             *
             * Normal:    value = 1.frac * 2^(exp - 127)
             * Subnormal: value = 0.frac * 2^(-126)
             */
            if (exp_a == 8'h00) begin
                mant_a    = {1'b0, frac_a};
                exp_unb_a = -126;
            end else begin
                mant_a    = {1'b1, frac_a};
                exp_unb_a = exp_a - 127;
            end

            if (exp_b == 8'h00) begin
                mant_b    = {1'b0, frac_b};
                exp_unb_b = -126;
            end else begin
                mant_b    = {1'b1, frac_b};
                exp_unb_b = exp_b - 127;
            end

            product = mant_a * mant_b;
            exp_sum = exp_unb_a + exp_unb_b;

            /*
             * product represents:
             *
             *   product * 2^(exp_sum - 46)
             *
             * Find the true leading bit of the product.  This is important
             * for subnormal operands, where the leading bit may be far below
             * bit 46.
             */
            prod_msb = msb_index(product);
            exp_norm = exp_sum + prod_msb - 46;

            /*
             * Normal result path.
             */
            if (exp_norm >= -126) begin
                shift_norm = prod_msb - 23;

                if (shift_norm > 0) begin
                    mant_pre  = product >> shift_norm;
                    guard_bit = product[shift_norm - 1];
                    sticky_bit = any_low_bits(product, shift_norm - 1);
                end else if (shift_norm == 0) begin
                    mant_pre  = product[23:0];
                    guard_bit = 1'b0;
                    sticky_bit = 1'b0;
                end else begin
                    mant_pre  = product << (-shift_norm);
                    guard_bit = 1'b0;
                    sticky_bit = 1'b0;
                end

                /*
                 * Round to nearest, ties to even.
                 */
                round_inc = guard_bit & (sticky_bit | mant_pre[0]);
                rounded   = {1'b0, mant_pre} + round_inc;

                exp_after_round = exp_norm;

                if (rounded[24]) begin
                    mant_pre = rounded[24:1];
                    exp_after_round = exp_after_round + 1;
                end else begin
                    mant_pre = rounded[23:0];
                end

                exp_field = exp_after_round + 127;

                if (exp_field >= 255) begin
                    y = {sign_y, 8'hff, 23'h000000};
                end else begin
                    y = {sign_y, exp_field[7:0], mant_pre[22:0]};
                end
            end else begin
                /*
                 * Subnormal result path.
                 *
                 * Subnormal encoding represents:
                 *
                 *   frac * 2^(-149)
                 *
                 * Exact integer before rounding is therefore:
                 *
                 *   product * 2^(exp_sum + 103)
                 *
                 * because product value is product * 2^(exp_sum - 46).
                 */
                scale_sub   = exp_sum + 103;
                wide_product = {80'h0, product};

                if (scale_sub >= 0) begin
                    sub_pre = wide_product << scale_sub;
                    sub_rounded = sub_pre;
                end else begin
                    shift_sub = -scale_sub;

                    if (shift_sub >= 48)
                        sub_pre = 128'h0;
                    else
                        sub_pre = product >> shift_sub;

                    if ((shift_sub >= 1) && (shift_sub <= 48))
                        guard_bit = product[shift_sub - 1];
                    else
                        guard_bit = 1'b0;

                    sticky_bit = any_low_bits(product, shift_sub - 1);

                    round_inc = guard_bit & (sticky_bit | sub_pre[0]);
                    sub_rounded = sub_pre + round_inc;
                end

                /*
                 * If subnormal rounding reaches 2^23, the result becomes the
                 * smallest normal number: exponent field 1, fraction 0.
                 */
                if (sub_rounded[127:23] != 105'h0) begin
                    y = {sign_y, 8'h01, 23'h000000};
                end else begin
                    y = {sign_y, 8'h00, sub_rounded[22:0]};
                end
            end
        end
    end

endmodule