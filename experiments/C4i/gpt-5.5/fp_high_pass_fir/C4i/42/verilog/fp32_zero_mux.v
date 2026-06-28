`timescale 1ns/1ps

module fp32_zero_mux (
    input         valid_in,
    input  [31:0] data_in,
    output [31:0] data_out
);

    // Insert IEEE-754 +0.0 on invalid cycles, otherwise pass input unchanged.
    assign data_out = valid_in ? data_in : 32'h00000000;

endmodule