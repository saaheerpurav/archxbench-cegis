`timescale 1ns/1ps

module fp_mult_special (
    input zero_a,
    input zero_b,
    input inf_a,
    input inf_b,
    input nan_a,
    input nan_b,
    output invalid,
    output is_nan,
    output is_inf,
    output is_zero
);
    wire zero_times_inf;

    assign zero_times_inf = (zero_a & inf_b) | (zero_b & inf_a);

    assign invalid = zero_times_inf;

    assign is_nan  = nan_a | nan_b | invalid;
    assign is_inf  = (inf_a | inf_b) & ~is_nan;
    assign is_zero = (zero_a | zero_b) & ~is_nan & ~is_inf;

endmodule