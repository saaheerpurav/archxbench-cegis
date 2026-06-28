`timescale 1ns/1ps

module fp_fir_tap_products_comb #(
    parameter TAP_CNT = 63
) (
    input  [TAP_CNT*32-1:0] samples_flat,
    input  [TAP_CNT*32-1:0] coeffs_flat,
    output [TAP_CNT*32-1:0] products_flat
);

    function automatic sticky_lower48;
        input [47:0] value;
        input integer nbits;
        integer si;
        begin
            sticky_lower48 = 1'b0;
            for (si = 0; si < 48; si = si + 1) begin
                if (si < nbits)
                    sticky_lower48 = sticky_lower48 | value[si];
            end
        end
    endfunction

    function automatic [5:0] msb_index48;
        input [47:0] value;
        integer mi;
        begin
            msb_index48 = 6'd0;
            for (mi = 0; mi < 48; mi = mi + 1) begin
                if (value[mi])
                    msb_index48 = mi[5:0];
            end
        end
    endfunction

    function automatic [31:0] fp32_mul;
        input [31:0] a;
        input [31:0] b;

        reg        sign;
        reg [7:0]  exp_a;
        reg [7:0]  exp_b;
        reg [22:0] frac_a;
        reg [22:0] frac_b;

        reg        a_is_nan;
        reg        b_is_nan;
        reg        a_is_inf;
        reg        b_is_inf;
        reg        a_is_zero;
        reg        b_is_zero;

        reg [23:0] mant_a;
        reg [23:0] mant_b;
        reg [47:0] prod;

        integer ea_unb;
        integer eb_unb;
        integer e_sum;
        integer ebase;
        integer k;
        integer e_norm;
        integer shift;
        integer s;
        integer rshift;

        reg [47:0] q48;
        reg [95:0] qext;
        reg        guard_bit;
        reg        sticky_bit;
        reg        inc;
        reg [24:0] rounded;
        reg [7:0]  exp_field;

        begin
            sign   = a[31] ^ b[31];
            exp_a  = a[30:23];
            exp_b  = b[30:23];
            frac_a = a[22:0];
            frac_b = b[22:0];

            a_is_nan  = (exp_a == 8'hff) && (frac_a != 23'd0);
            b_is_nan  = (exp_b == 8'hff) && (frac_b != 23'd0);
            a_is_inf  = (exp_a == 8'hff) && (frac_a == 23'd0);
            b_is_inf  = (exp_b == 8'hff) && (frac_b == 23'd0);
            a_is_zero = (exp_a == 8'h00) && (frac_a == 23'd0);
            b_is_zero = (exp_b == 8'h00) && (frac_b == 23'd0);

            if (a_is_nan || b_is_nan) begin
                fp32_mul = 32'h7fc00000;
            end else if ((a_is_inf && b_is_zero) || (b_is_inf && a_is_zero)) begin
                fp32_mul = 32'h7fc00000;
            end else if (a_is_inf || b_is_inf) begin
                fp32_mul = {sign, 8'hff, 23'h000000};
            end else if (a_is_zero || b_is_zero) begin
                fp32_mul = {sign, 31'h00000000};
            end else begin
                mant_a = (exp_a == 8'h00) ? {1'b0, frac_a} : {1'b1, frac_a};
                mant_b = (exp_b == 8'h00) ? {1'b0, frac_b} : {1'b1, frac_b};

                ea_unb = (exp_a == 8'h00) ? -126 : (exp_a - 127);
                eb_unb = (exp_b == 8'h00) ? -126 : (exp_b - 127);

                prod  = mant_a * mant_b;
                e_sum = ea_unb + eb_unb;

                /*
                 * Exact value is:
                 *
                 *   prod * 2^(e_sum - 46)
                 *
                 * because each 24-bit mantissa represents significand * 2^23.
                 */
                ebase = e_sum - 46;
                k     = msb_index48(prod);
                e_norm = ebase + k;

                /*
                 * Normal result path.
                 */
                if (e_norm >= -126) begin
                    shift = k - 23;

                    if (shift > 0) begin
                        q48        = prod >> shift;
                        guard_bit  = prod[shift-1];
                        sticky_bit = sticky_lower48(prod, shift-1);
                    end else begin
                        q48        = prod << (-shift);
                        guard_bit  = 1'b0;
                        sticky_bit = 1'b0;
                    end

                    inc     = guard_bit & (sticky_bit | q48[0]);
                    rounded = {1'b0, q48[23:0]} + inc;

                    if (rounded[24]) begin
                        rounded = rounded >> 1;
                        e_norm  = e_norm + 1;
                    end

                    if (e_norm >= 128) begin
                        fp32_mul = {sign, 8'hff, 23'h000000};
                    end else begin
                        exp_field = e_norm + 127;
                        fp32_mul  = {sign, exp_field, rounded[22:0]};
                    end
                end

                /*
                 * Subnormal/underflow result path.
                 *
                 * A subnormal float encodes:
                 *
                 *   frac * 2^-149
                 *
                 * Therefore frac is the rounded value of:
                 *
                 *   prod * 2^(ebase + 149)
                 */
                else begin
                    s = ebase + 149;
                    qext       = 96'd0;
                    guard_bit  = 1'b0;
                    sticky_bit = 1'b0;

                    if (s >= 0) begin
                        qext = ({48'd0, prod} << s);
                    end else begin
                        rshift = -s;

                        if (rshift < 48)
                            qext = prod >> rshift;
                        else
                            qext = 96'd0;

                        if ((rshift > 0) && ((rshift - 1) < 48))
                            guard_bit = prod[rshift-1];
                        else
                            guard_bit = 1'b0;

                        if (rshift > 1)
                            sticky_bit = sticky_lower48(prod, rshift-1);
                        else
                            sticky_bit = 1'b0;

                        inc = guard_bit & (sticky_bit | qext[0]);
                        qext = qext + inc;
                    end

                    if (qext[23]) begin
                        /*
                         * Rounded up to the minimum normal value.
                         */
                        fp32_mul = {sign, 8'h01, qext[22:0]};
                    end else if (qext[22:0] == 23'd0) begin
                        fp32_mul = {sign, 31'h00000000};
                    end else begin
                        fp32_mul = {sign, 8'h00, qext[22:0]};
                    end
                end
            end
        end
    endfunction

    genvar i;
    generate
        for (i = 0; i < TAP_CNT; i = i + 1) begin : GEN_TAP_PRODUCTS
            assign products_flat[i*32 +: 32] =
                fp32_mul(samples_flat[i*32 +: 32],
                         coeffs_flat [i*32 +: 32]);
        end
    endgenerate

endmodule