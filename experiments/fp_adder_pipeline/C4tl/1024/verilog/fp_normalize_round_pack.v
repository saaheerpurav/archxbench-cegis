`timescale 1ns/1ps

module fp_normalize_round_pack (
    input        sign_in,
    input [7:0]  exp_in,
    input [27:0] sig_in,
    input        is_zero,
    output [31:0] result
);

reg [27:0] sig_norm;
reg [7:0]  exp_norm;
reg [22:0] frac;
reg        guard_bit;
reg        round_bit;
reg        sticky_bit;
reg        round_inc;
reg [23:0] rounded_sig;
reg [31:0] result_r;
integer i;

always @(*) begin
    sig_norm    = sig_in;
    exp_norm    = exp_in;
    frac        = 23'b0;
    guard_bit   = 1'b0;
    round_bit   = 1'b0;
    sticky_bit  = 1'b0;
    round_inc   = 1'b0;
    rounded_sig = 24'b0;
    result_r    = 32'b0;

    if (is_zero || (sig_in == 28'b0)) begin
        result_r = {sign_in, 8'b0, 23'b0};
    end else if (exp_in == 8'hff) begin
        result_r = {sign_in, 8'hff, 23'b0};
    end else begin
        if (sig_norm[27]) begin
            sig_norm = {1'b0, sig_norm[27:1]};
            sig_norm[0] = sig_in[1] | sig_in[0];

            if (exp_norm == 8'hfe) begin
                exp_norm = 8'hff;
            end else begin
                exp_norm = exp_norm + 8'd1;
            end
        end else begin
            for (i = 0; i < 27; i = i + 1) begin
                if (!sig_norm[26] && (exp_norm > 8'd0)) begin
                    sig_norm = sig_norm << 1;
                    exp_norm = exp_norm - 8'd1;
                end
            end
        end

        if (exp_norm == 8'hff) begin
            result_r = {sign_in, 8'hff, 23'b0};
        end else begin
            frac       = sig_norm[25:3];
            guard_bit  = sig_norm[2];
            round_bit  = sig_norm[1];
            sticky_bit = sig_norm[0];

            round_inc = guard_bit && (round_bit || sticky_bit || frac[0]);
            rounded_sig = {1'b1, frac} + {23'b0, round_inc};

            if (rounded_sig[23] == 1'b0) begin
                if (exp_norm == 8'hfe) begin
                    result_r = {sign_in, 8'hff, 23'b0};
                end else begin
                    result_r = {sign_in, exp_norm + 8'd1, rounded_sig[22:0]};
                end
            end else if (exp_norm == 8'd0) begin
                result_r = {sign_in, 8'b0, sig_norm[25:3]};
            end else begin
                result_r = {sign_in, exp_norm, rounded_sig[22:0]};
            end
        end
    end
end

assign result = result_r;

endmodule