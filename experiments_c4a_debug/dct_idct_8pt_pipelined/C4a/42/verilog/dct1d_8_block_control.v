`timescale 1ns/1ps

module dct1d_8_block_control (
    input        valid_in,
    input  [2:0] index,
    input        emitting,
    input  [2:0] emit_index,
    output       block_last,
    output [2:0] next_emit_index,
    output       emit_done
);

    assign block_last      = valid_in && (index == 3'd7);
    assign next_emit_index = emit_index + 3'd1;
    assign emit_done       = emitting && (emit_index == 3'd7);

endmodule