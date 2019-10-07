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


module main(
    input wire clk,
    input wire rst,
    input wire[15:0] data,
    output wire[15:0] r
);

wire[15:0] a;
wire[15:0] b;
wire[3:0] op;

state_machine st_m(.clk(clk), .rst(rst), .data(data), .op(op), .a(a), .b(b));
alu alu_1(.op(op), .a(a), .b(b), .r(r));

endmodule
