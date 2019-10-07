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
    output wire[3:0] op,
    output reg[15:0] a,
    output reg[15:0] b
);

reg[1:0] curr_st, next_st;

// 更新状态
always @(posedge clk or posedge rst) begin
    if (rst)
        curr_st <= 0;
    else
        curr_st <= next_st;
end

// 状态转移
always @(curr_st) begin
    case (curr_st)
        2'b00: next_st = 2'b01;
        2'b01: next_st = 2'b10;
        2'b10: next_st = 2'b11;
        2'b11: next_st = 2'b00;
    endcase
end

// 组合输出
always @(posedge clk or posedge rst) begin
    if(rst) begin
        a <= data;
        b <= 0;
    end else begin
        case (next_st)
            2'b01: {a, b} <= {data, b};
            2'b10: {a, b} <= {a, data};
            2'b11: {a, b} <= {a, b};
            2'b00: {a, b} <= 0;
        endcase
    end
end

// 操作码实时更新，纯组合逻辑，和时序逻辑无关
assign op = (curr_st == 2'b10)? data[3:0]:
            (curr_st == 2'b11)? `OP_OVF: `OP_NOP;

endmodule
