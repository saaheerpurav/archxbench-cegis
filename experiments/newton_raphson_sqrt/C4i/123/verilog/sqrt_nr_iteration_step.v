`timescale 1ns/1ps

module sqrt_nr_iteration_step #(
    parameter N = 16,
    parameter M = 8
)(
    input  [N-1:0] X,
    input  [N-1:0] y_current,
    output reg [N-1:0] y_next
);

    reg [N+M-1:0] scaled_x;
    reg [N+M-1:0] div_term;
    reg [N+M:0]   sum_term;

    always @(*) begin
        scaled_x = {N+M{1'b0}};
        div_term = {N+M{1'b0}};
        sum_term = {N+M+1{1'b0}};
        y_next   = {N{1'b0}};

        if (y_current != {N{1'b0}}) begin
            scaled_x = {{M{1'b0}}, X} << M;
            div_term = scaled_x / y_current;
            sum_term = {{(M+1){1'b0}}, y_current} + {1'b0, div_term};

            if (|sum_term[N+M:N+1])
                y_next = {N{1'b1}};
            else
                y_next = sum_term[N:1];
        end
    end

endmodule