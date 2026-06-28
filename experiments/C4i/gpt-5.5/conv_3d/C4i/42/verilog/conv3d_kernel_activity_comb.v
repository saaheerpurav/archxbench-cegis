`timescale 1ns/1ps

module conv3d_kernel_activity_comb #(
    parameter KERNEL_W = 216
) (
    input  [((KERNEL_W > 0) ? KERNEL_W : 1)-1:0] kernel,
    output                                       kernel_nonzero
);

    generate
        if (KERNEL_W > 0) begin : gen_kernel_active
            // Assert when any bit of the flattened kernel vector is set.
            assign kernel_nonzero = |kernel;
        end else begin : gen_kernel_inactive
            // Degenerate protection: a zero-width logical kernel is treated as inactive.
            assign kernel_nonzero = 1'b0;
        end
    endgenerate

endmodule