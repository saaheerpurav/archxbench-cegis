`timescale 1ns/1ps

module fp_normalize_round_pack (
    input        special_valid,
    input [31:0] special_result,
    input        sign,
    input  [7:0] exp,
    input [27:0] mant,
    output reg [31:0] result
);

    reg [8:0]  exp_work;
    reg [26:0] m;
    reg        round_inc;
    reg [24:0] rounded;
    reg [23:0] sig24;
    integer    i;

    always @* begin
        result    = 32'h00000000;
        exp_work  = 9'd0;
        m         = 27'd0;
        round_inc = 1'b0;
        rounded   = 25'd0;
        sig24     = 24'd0;

        if (special_valid) begin
            result = special_result;
        end else if (mant == 28'd0) begin
            /*
             * Exact cancellation and all-zero results are packed as +0.
             * This also matches IEEE-754 addition behavior for -0 + +0
             * under round-to-nearest-even.
             */
            result = 32'h00000000;
        end else begin
            exp_work = {1'b0, exp};

            /*
             * Handle carry-out from significand addition.
             *
             * Incoming mantissa layout is effectively:
             *   mant[27]   : carry bit
             *   mant[26:3] : significand including hidden bit
             *   mant[2]    : guard
             *   mant[1]    : round
             *   mant[0]    : sticky
             *
             * If carry is present, shift right by one and jam the discarded
             * low bits into the new sticky bit.
             */
            if (mant[27]) begin
                m        = mant[27:1];
                m[0]     = mant[1] | mant[0];
                exp_work = {1'b0, exp} + 9'd1;
            end else begin
                m = mant[26:0];
            end

            /*
             * Normalize left after subtraction/cancellation.
             *
             * Stop at biased exponent 1.  At that point, if the hidden bit is
             * still zero, the value is below the normal range and must be
             * packed as a subnormal/denormal.
             */
            for (i = 0; i < 27; i = i + 1) begin
                if ((m[26] == 1'b0) && (exp_work > 9'd1) && (m != 27'd0)) begin
                    m        = m << 1;
                    exp_work = exp_work - 9'd1;
                end
            end

            /*
             * Some pipelines use exponent 0 for arithmetic involving
             * subnormal operands.  If the significand has grown a hidden bit
             * before rounding, promote the working exponent to 1 so that any
             * subsequent rounding carry advances to exponent 2 correctly.
             */
            if ((exp_work == 9'd0) && (m[26] == 1'b1)) begin
                exp_work = 9'd1;
            end

            /*
             * Round-to-nearest-even.
             *
             * m[2] is guard, m[1] is round, m[0] is sticky, and m[3] is the
             * current least-significant retained bit.  On an exact halfway
             * case, increment only if the retained LSB is one, producing an
             * even result.
             */
            round_inc = m[2] & (m[1] | m[0] | m[3]);
            rounded   = {1'b0, m[26:3]} + {24'd0, round_inc};

            /*
             * Rounding may overflow the 24-bit significand from
             * 1.111... to 10.000..., requiring a right normalization and
             * exponent increment.
             */
            if (rounded[24]) begin
                sig24    = rounded[24:1];
                exp_work = exp_work + 9'd1;
            end else begin
                sig24 = rounded[23:0];
            end

            /*
             * Pack final IEEE-754 single-precision result.
             */
            if (exp_work >= 9'h0ff) begin
                result = {sign, 8'hff, 23'd0};
            end else if (sig24 == 24'd0) begin
                result = 32'h00000000;
            end else if (exp_work == 9'd0) begin
                /*
                 * True subnormal path.  Rounding can promote the largest
                 * subnormal to the minimum normal.
                 */
                if (sig24[23]) begin
                    result = {sign, 8'd1, sig24[22:0]};
                end else begin
                    result = {sign, 8'd0, sig24[22:0]};
                end
            end else if ((exp_work == 9'd1) && (sig24[23] == 1'b0)) begin
                /*
                 * Underflow into denormal range.
                 */
                result = {sign, 8'd0, sig24[22:0]};
            end else begin
                result = {sign, exp_work[7:0], sig24[22:0]};
            end
        end
    end

endmodule