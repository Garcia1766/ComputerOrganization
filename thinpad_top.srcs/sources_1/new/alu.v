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
    output wire[15:0] r
);

reg[15:0] r1;
reg ovf;

always @(op) begin
    case (op)
        `OP_ADD: begin
            r1 = a + b;
            ovf = (a[15] ~^ b[15]) & (a[15] ^ r1[15]);
        end
        `OP_SUB: begin
            r1 = a - b;
            ovf = (a[15] ^ b[15]) & (b[15] ~^ r1[15]);
        end
        `OP_AND: {ovf, r1} = {1'b0, a & b};
        `OP_OR : {ovf, r1} = {1'b0, a | b};
        `OP_XOR: {ovf, r1} = {1'b0, a ^ b};
        `OP_NOT: {ovf, r1} = {1'b0, ~a};
        `OP_SLL: {ovf, r1} = {1'b0, a << b[4:0]};
        `OP_SRL: {ovf, r1} = {1'b0, a >> b[4:0]};
        `OP_SRA: {ovf, r1} = {1'b0, ($signed(a)) >>> b[4:0]};
        `OP_ROL: {ovf, r1} = {1'b0, (a << b[3:0]) | (a >> (16-b[3:0]))};
        `OP_OVF: {ovf, r1} = {ovf, r1};
        default: {ovf, r1} = 0;
    endcase
end

assign r = (op == `OP_OVF)? {15'b000_0000_0000_0000, ovf}: r1;

endmodule
