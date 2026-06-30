`timescale 1ns/1ps

module fp_normalize_round_pack #(
    parameter EXP_WIDTH  = 8,
    parameter MANT_WIDTH = 23,
    parameter WIDTH      = 1 + EXP_WIDTH + MANT_WIDTH
)(
    input  wire                         result_sign,
    input  wire signed [EXP_WIDTH+2:0]  raw_exp,
    input  wire [(2*(MANT_WIDTH+1))-1:0] sig_product,
    input  wire [2:0]                  rnd_mode,
    output reg  [WIDTH-1:0]            result,
    output reg  [2:0]                  flags
);

    localparam integer PROD_WIDTH  = 2 * (MANT_WIDTH + 1);
    localparam integer EXP_MAX_INT = (1 << EXP_WIDTH) - 1;

    reg signed [EXP_WIDTH+2:0] norm_exp;
    reg [MANT_WIDTH:0]         mant_full;
    reg                        guard_bit;
    reg                        sticky_bit;
    reg                        round_inc;
    reg [MANT_WIDTH+1:0]       rounded_mant;
    reg [EXP_WIDTH-1:0]        packed_exp;

    integer j;

    always @(*) begin
        result      = {WIDTH{1'b0}};
        flags       = 3'b000;
        norm_exp    = raw_exp;
        mant_full   = {MANT_WIDTH+1{1'b0}};
        guard_bit   = 1'b0;
        sticky_bit  = 1'b0;
        round_inc   = 1'b0;
        rounded_mant = {MANT_WIDTH+2{1'b0}};
        packed_exp  = {EXP_WIDTH{1'b0}};

        if (sig_product == {PROD_WIDTH{1'b0}}) begin
            result = {result_sign, {EXP_WIDTH{1'b0}}, {MANT_WIDTH{1'b0}}};
            flags  = 3'b001;
        end else begin
            if (sig_product[PROD_WIDTH-1]) begin
                norm_exp  = raw_exp + 1'b1;
                mant_full = sig_product[PROD_WIDTH-1 -: (MANT_WIDTH+1)];
                guard_bit = sig_product[PROD_WIDTH-MANT_WIDTH-2];

                sticky_bit = 1'b0;
                for (j = 0; j < PROD_WIDTH-MANT_WIDTH-2; j = j + 1)
                    sticky_bit = sticky_bit | sig_product[j];
            end else begin
                norm_exp  = raw_exp;
                mant_full = sig_product[PROD_WIDTH-2 -: (MANT_WIDTH+1)];
                guard_bit = sig_product[PROD_WIDTH-MANT_WIDTH-3];

                sticky_bit = 1'b0;
                for (j = 0; j < PROD_WIDTH-MANT_WIDTH-3; j = j + 1)
                    sticky_bit = sticky_bit | sig_product[j];
            end

            case (rnd_mode)
                3'b000: round_inc = guard_bit & (sticky_bit | mant_full[0]);
                3'b001: round_inc = 1'b0;
                3'b010: round_inc = result_sign & (guard_bit | sticky_bit);
                3'b011: round_inc = ~result_sign & (guard_bit | sticky_bit);
                default: round_inc = guard_bit & (sticky_bit | mant_full[0]);
            endcase

            rounded_mant = {1'b0, mant_full} + round_inc;

            if (rounded_mant[MANT_WIDTH+1]) begin
                norm_exp  = norm_exp + 1'b1;
                mant_full = rounded_mant[MANT_WIDTH+1:1];
            end else begin
                mant_full = rounded_mant[MANT_WIDTH:0];
            end

            if (norm_exp >= EXP_MAX_INT) begin
                result = {result_sign, {EXP_WIDTH{1'b1}}, {MANT_WIDTH{1'b0}}};
                flags  = 3'b010;
            end else if (norm_exp <= 0) begin
                result = {result_sign, {EXP_WIDTH{1'b0}}, {MANT_WIDTH{1'b0}}};
                flags  = 3'b001;
            end else begin
                packed_exp = norm_exp[EXP_WIDTH-1:0];
                result = {result_sign, packed_exp, mant_full[MANT_WIDTH-1:0]};
                flags  = 3'b000;
            end
        end
    end

endmodule