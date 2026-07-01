`timescale 1ns/1ps

module fp_normalize (
    input sign_in,
    input [7:0] exp_in,
    input [27:0] mag_in,
    output sign_out,
    output [7:0] exp_out,
    output [26:0] sig_out,
    output is_zero
);

reg [7:0]  exp_r;
reg [26:0] sig_r;
reg        zero_r;

reg [4:0] lshift;
reg [27:0] shifted;

assign sign_out = zero_r ? 1'b0 : sign_in;
assign exp_out  = exp_r;
assign sig_out  = sig_r;
assign is_zero  = zero_r;

always @(*) begin
    exp_r  = 8'd0;
    sig_r  = 27'd0;
    zero_r = (mag_in == 28'd0);
    lshift = 5'd0;
    shifted = 28'd0;

    if (!zero_r) begin
        if (mag_in[27]) begin
            exp_r = exp_in + 8'd1;
            sig_r = {mag_in[27:2], (mag_in[1] | mag_in[0])};
        end else if (mag_in[26]) begin
            exp_r = exp_in;
            sig_r = mag_in[26:0];
        end else begin
            casex (mag_in[26:0])
                27'b01xxxxxxxxxxxxxxxxxxxxxxxxx: lshift = 5'd1;
                27'b001xxxxxxxxxxxxxxxxxxxxxxxx: lshift = 5'd2;
                27'b0001xxxxxxxxxxxxxxxxxxxxxxx: lshift = 5'd3;
                27'b00001xxxxxxxxxxxxxxxxxxxxxx: lshift = 5'd4;
                27'b000001xxxxxxxxxxxxxxxxxxxxx: lshift = 5'd5;
                27'b0000001xxxxxxxxxxxxxxxxxxxx: lshift = 5'd6;
                27'b00000001xxxxxxxxxxxxxxxxxxx: lshift = 5'd7;
                27'b000000001xxxxxxxxxxxxxxxxxx: lshift = 5'd8;
                27'b0000000001xxxxxxxxxxxxxxxxx: lshift = 5'd9;
                27'b00000000001xxxxxxxxxxxxxxxx: lshift = 5'd10;
                27'b000000000001xxxxxxxxxxxxxxx: lshift = 5'd11;
                27'b0000000000001xxxxxxxxxxxxxx: lshift = 5'd12;
                27'b00000000000001xxxxxxxxxxxxx: lshift = 5'd13;
                27'b000000000000001xxxxxxxxxxxx: lshift = 5'd14;
                27'b0000000000000001xxxxxxxxxxx: lshift = 5'd15;
                27'b00000000000000001xxxxxxxxxx: lshift = 5'd16;
                27'b000000000000000001xxxxxxxxx: lshift = 5'd17;
                27'b0000000000000000001xxxxxxxx: lshift = 5'd18;
                27'b00000000000000000001xxxxxxx: lshift = 5'd19;
                27'b000000000000000000001xxxxxx: lshift = 5'd20;
                27'b0000000000000000000001xxxxx: lshift = 5'd21;
                27'b00000000000000000000001xxxx: lshift = 5'd22;
                27'b000000000000000000000001xxx: lshift = 5'd23;
                27'b0000000000000000000000001xx: lshift = 5'd24;
                27'b00000000000000000000000001x: lshift = 5'd25;
                27'b000000000000000000000000001: lshift = 5'd26;
                default:                            lshift = 5'd0;
            endcase

            if (exp_in > lshift) begin
                shifted = mag_in << lshift;
                exp_r = exp_in - lshift;
                sig_r = shifted[26:0];
            end else begin
                shifted = mag_in << (exp_in - 8'd1);
                exp_r = 8'd0;
                sig_r = shifted[26:0];
            end
        end
    end
end

endmodule