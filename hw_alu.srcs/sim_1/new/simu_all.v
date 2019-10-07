`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 2019/10/06 22:32:46
// Design Name:
// Module Name: simu_all
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


module simu_all();

reg clk = 0;
reg rst = 0;
reg[15:0] data = 16'b0100_0000_0000_0001;
wire[15:0] r;

initial begin

    rst = 0;
    #5  rst = 1;
    #5  rst = 0;
        data = 16'b0100_0000_0000_0000;
    #40 data = 16'b0100_0000_0000_0010;
    #40 data = 16'b1000_0000_0000_0001;


end

always #20 clk = ~clk;

main mytest(.clk(clk), .rst(rst), .data(data), .r(r));

endmodule
