`timescale 1ns/1ps

module fp32_mul (
    input  [31:0] a,
    input  [31:0] b,
    output [31:0] result
);

    wire a_is_zero = (a[30:23] == 8'h00) && (a[22:0] == 23'h000000);
    wire b_is_zero = (b[30:23] == 8'h00) && (b[22:0] == 23'h000000);

    wire a_is_inf  = (a[30:23] == 8'hff) && (a[22:0] == 23'h000000);
    wire b_is_inf  = (b[30:23] == 8'hff) && (b[22:0] == 23'h000000);

    wire a_is_nan  = (a[30:23] == 8'hff) && (a[22:0] != 23'h000000);
    wire b_is_nan  = (b[30:23] == 8'hff) && (b[22:0] != 23'h000000);

    wire res_sign  = a[31] ^ b[31];

    real ar;
    real br;
    real rr;

    reg [31:0] result_r;

    assign result = result_r;

    always @* begin
        if (a_is_nan || b_is_nan) begin
            result_r = 32'h7fc00000;
        end else if ((a_is_inf && b_is_zero) || (b_is_inf && a_is_zero)) begin
            result_r = 32'h7fc00000;
        end else if (a_is_inf || b_is_inf) begin
            result_r = {res_sign, 8'hff, 23'h000000};
        end else if (a_is_zero || b_is_zero) begin
            result_r = {res_sign, 8'h00, 23'h000000};
        end else begin
            ar = fp32_to_real(a);
            br = fp32_to_real(b);
            rr = ar * br;
            result_r = real_to_fp32(rr);
        end
    end

    function real pow2_real;
        input integer e;
        integer k;
        real r;
        begin
            r = 1.0;

            if (e >= 0) begin
                for (k = 0; k < e; k = k + 1)
                    r = r * 2.0;
            end else begin
                for (k = 0; k < -e; k = k + 1)
                    r = r / 2.0;
            end

            pow2_real = r;
        end
    endfunction

    function real fp32_to_real;
        input [31:0] x;

        integer exp_field;
        integer frac_field;
        real mant;
        real val;

        begin
            exp_field  = x[30:23];
            frac_field = x[22:0];

            if (exp_field == 255) begin
                if (frac_field == 0)
                    val = 1.0e300;
                else
                    val = 0.0;
            end else if (exp_field == 0) begin
                if (frac_field == 0) begin
                    val = 0.0;
                end else begin
                    mant = frac_field / 8388608.0;
                    val  = mant * pow2_real(-126);
                end
            end else begin
                mant = 1.0 + (frac_field / 8388608.0);
                val  = mant * pow2_real(exp_field - 127);
            end

            if (x[31])
                fp32_to_real = -val;
            else
                fp32_to_real = val;
        end
    endfunction

    function integer round_nearest_even;
        input real x;

        integer base;
        real frac;

        begin
            if (x <= 0.0) begin
                round_nearest_even = 0;
            end else begin
                base = $rtoi(x);
                frac = x - base;

                if (frac > 0.5) begin
                    base = base + 1;
                end else if (frac == 0.5) begin
                    if ((base % 2) != 0)
                        base = base + 1;
                end

                round_nearest_even = base;
            end
        end
    endfunction

    function [31:0] real_to_fp32;
        input real v;

        reg sign_bit;
        reg [7:0] exp_bits;
        reg [22:0] frac_bits;

        real av;
        real norm;
        real scaled;

        integer exp_unbiased;
        integer exp_field;
        integer frac_int;

        begin
            if (v == 0.0) begin
                real_to_fp32 = 32'h00000000;
            end else begin
                sign_bit = (v < 0.0) ? 1'b1 : 1'b0;

                if (sign_bit)
                    av = -v;
                else
                    av = v;

                norm = av;
                exp_unbiased = 0;

                while (norm >= 2.0) begin
                    norm = norm / 2.0;
                    exp_unbiased = exp_unbiased + 1;
                end

                while (norm < 1.0) begin
                    norm = norm * 2.0;
                    exp_unbiased = exp_unbiased - 1;
                end

                exp_field = exp_unbiased + 127;

                if (exp_field <= 0) begin
                    scaled = av * pow2_real(149);
                    frac_int = round_nearest_even(scaled);

                    if (frac_int <= 0) begin
                        real_to_fp32 = {sign_bit, 8'h00, 23'h000000};
                    end else if (frac_int >= 8388608) begin
                        real_to_fp32 = {sign_bit, 8'h01, 23'h000000};
                    end else begin
                        exp_bits  = 8'h00;
                        frac_bits = frac_int[22:0];
                        real_to_fp32 = {sign_bit, exp_bits, frac_bits};
                    end
                end else begin
                    scaled = (norm - 1.0) * 8388608.0;
                    frac_int = round_nearest_even(scaled);

                    if (frac_int >= 8388608) begin
                        frac_int = 0;
                        exp_field = exp_field + 1;
                    end

                    if (exp_field >= 255) begin
                        real_to_fp32 = {sign_bit, 8'hff, 23'h000000};
                    end else begin
                        exp_bits  = exp_field[7:0];
                        frac_bits = frac_int[22:0];
                        real_to_fp32 = {sign_bit, exp_bits, frac_bits};
                    end
                end
            end
        end
    endfunction

endmodule