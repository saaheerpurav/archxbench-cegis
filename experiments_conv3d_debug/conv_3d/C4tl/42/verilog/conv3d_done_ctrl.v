`timescale 1ns/1ps

module conv3d_done_ctrl (
    input  valid_in,
    input  last_in,
    output done
);

    assign done = valid_in & last_in;

endmodule