`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 2019/10/06 21:59:31
// Design Name:
// Module Name: simu_statemachine
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


module simu_statemachine();

reg clk = 0;
reg rst = 0;
reg[15:0] data = 16'b0000_0000_0000_0010;
wire[3:0] op;
wire[15:0] a;
wire[15:0] b;

initial begin

rst = 0;
#10 rst = 1;
#20 rst = 0;

end

always #20 clk = ~clk;

state_machine mytest(clk, rst, data, op, a, b);

endmodule
