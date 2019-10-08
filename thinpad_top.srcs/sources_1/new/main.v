`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 2019/10/06 10:35:52
// Design Name:
// Module Name: main
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

module main(
    input wire clk,
    input wire rst,
    input wire[15:0] data,
    output wire[15:0] f
);

wire[15:0] a;
wire[15:0] b;
wire[3:0] op;
wire[1:0] st;
wire ovf;
wire[15:0] r;

state_machine st_m(.clk(clk), .rst(rst), .data(data), .op(op), .a(a), .b(b), .st(st));
alu alu_1(.op(op), .a(a), .b(b), .r(r), .ovf(ovf));

assign f = (st == `ST3)? {15'b000_0000_0000_0000, ovf}:
           (st == `ST2)? r: 0;

endmodule
