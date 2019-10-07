`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 2019/10/06 14:50:05
// Design Name:
// Module Name: def
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

`define OP_NOP 4'b0000 // nop
`define OP_ADD 4'b0001 // A + B
`define OP_SUB 4'b0010 // A - B
`define OP_AND 4'b0011 // A and B
`define OP_OR  4'b0100 // A or B
`define OP_XOR 4'b0101 // A xor B
`define OP_NOT 4'b0110 // not A
`define OP_SLL 4'b0111 // A sll B
`define OP_SRL 4'b1000 // A srl B
`define OP_SRA 4'b1001 // A sra B
`define OP_ROL 4'b1010 // A rol B
`define OP_OVF 4'b1011 // overflow
