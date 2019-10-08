`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 2019/10/06 10:35:52
// Design Name:
// Module Name: state_machine
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

// 三段式状态机
module state_machine(
    input wire clk,
    input wire rst,
    input wire[15:0] data,
    output reg[3:0] op,
    output reg[15:0] a,
    output reg[15:0] b,
    output wire[1:0] st
);

reg[1:0] curr_st, next_st;

// 更新状态
always @(posedge clk or posedge rst) begin
    if (rst)
        curr_st <= `ST0;
    else
        curr_st <= next_st;
end

// 状态转移
always @(curr_st) begin
    case (curr_st)
        `ST0: next_st = `ST1;
        `ST1: next_st = `ST2;
        `ST2: next_st = `ST3;
        `ST3: next_st = `ST0;
    endcase
end

// 组合输出
always @(curr_st, data) begin
    case (curr_st)
        `ST0: a = data;
        `ST1: b = data;
        `ST2: op = data[3:0];
    endcase
end

assign st = curr_st;

endmodule
