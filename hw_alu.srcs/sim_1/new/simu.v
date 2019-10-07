`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 2019/10/06 10:52:00
// Design Name:
// Module Name: simu
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

module simu();

reg[3:0] op;
wire[3:0] op_in;
reg[15:0] a = 16'b0100_0001_1110_0100;
reg[15:0] b = 16'b0111_1011_1001_0001;
wire[15:0] out;

assign op_in = op;

initial begin
        op = 4'b0000;
    #20 op = 4'b0001;
    #20 op = 4'b1011;

    #20 op = 4'b0000;
        a = 16'b0100_0000_0000_0011;
    #20 op = 4'b0010;
    #20 op = 4'b1011;

    #20 op = 4'b0000;
    #20 op = 4'b0011;
    #20 op = 4'b1011;

    #20 op = 4'b0000;
    #20 op = 4'b0100;
    #20 op = 4'b1011;

    #20 op = 4'b0000;
    #20 op = 4'b0101;
    #20 op = 4'b1011;

    #20 op = 4'b0000;
    #20 op = 4'b0110;
    #20 op = 4'b1011;

    #20 op = 4'b0000;
    #20 op = 4'b0111;
    #20 op = 4'b1011;

    #20 op = 4'b0000;
    #20 op = 4'b1000;
    #20 op = 4'b1011;

    #20 op = 4'b0000;
        a = 16'b1100_0000_0000_0011;
    #20 op = 4'b1001;
    #20 op = 4'b1011;

    #20 op = 4'b0000;
    #20 op = 4'b1010;
    #20 op = 4'b1011;
end


alu mytest(op_in, a, b, out);

endmodule
