`timescale 1ns/1ps

module gd_iter_done(
    input  [31:0] iter_count,
    input  [31:0] max_iter,
    output        done
);

    assign done = (max_iter == 32'd0) || (iter_count >= (max_iter - 32'd1));

endmodule