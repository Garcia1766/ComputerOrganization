`include "defines.sv"

module mem_wb(

    input wire              clk,
    input wire              rst,

    //来自访存阶段的信息
    input wire[`RegAddrBus] mem_wd,     // 回写寄存器
    input wire              mem_wreg,   // 是否回写
    input wire[`RegBus]     mem_wdata,  // 回写数据

    //送到回写阶段的信息
    output reg[`RegAddrBus] wb_wd,
    output reg              wb_wreg,
    output reg[`RegBus]     wb_wdata
);

always @ (posedge clk) begin
    if(rst == `RstEnable) begin
        wb_wd    <= `NOPRegAddr;
        wb_wreg  <= `WriteDisable;
        wb_wdata <= `ZeroWord;
    end else begin
        wb_wd    <= mem_wd;
        wb_wreg  <= mem_wreg;
        wb_wdata <= mem_wdata;
    end    //if
end      //always


endmodule