`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 2019/10/06 10:35:52
// Design Name:
// Module Name: alu
// Project Name:
// Target Devices:
// Tool Versions:
// Description:
//
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////

`include "def.v"

module alu(
    input wire[3:0] op,
    input wire[15:0] a,
    input wire[15:0] b,
    output reg[15:0] r,
    output reg ovf
);

always @(op, a, b) begin
    case (op)
        `OP_ADD: r = a + b;
        `OP_SUB: r = a - b;
        `OP_AND: r = a & b;
        `OP_OR : r = a | b;
        `OP_XOR: r = a ^ b;
        `OP_NOT: r = ~a;
        `OP_SLL: r = a << b[4:0];
        `OP_SRL: r = a >> b[4:0];
        `OP_SRA: r = ($signed(a)) >>> b[4:0];
        `OP_ROL: r = (a << b[3:0]) | (a >> (16-b[3:0]));
        default: r = 0;
    endcase
    case (op)
        `OP_ADD: ovf = (a[15] ~^ b[15]) & (a[15] ^ r[15]);
        `OP_SUB: ovf = (a[15] ^ b[15]) & (b[15] ~^ r[15]);
        default: ovf = 0;
    endcase
end

endmodule
