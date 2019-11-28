`include "defines.sv"

module mem_wb(

    input wire              clk,
    input wire              rst,

    //来自mem阶段的信息
    input wire[`RegAddrBus] mem_wd,     // 回写寄存器
    input wire              mem_wreg,   // 是否回写
    input wire[`RegBus]     mem_wdata,  // 回写数据

    input wire[5:0]         stall,

    //送到wb阶段的信息
    output reg[`RegAddrBus] wb_wd,
    output reg              wb_wreg,
    output reg[`RegBus]     wb_wdata,

    //cp0相关信号
    input wire              mem_cp0_reg_we,
    input wire[4:0]         mem_cp0_reg_write_addr,
    input wire[`RegBus]     mem_cp0_reg_data,
    output reg              wb_cp0_reg_we,
    output reg[4:0]         wb_cp0_reg_write_addr,
    output reg[`RegBus]     wb_cp0_reg_data
);

always_ff @ (posedge clk) begin
    if(rst == `RstEnable || (stall[4] == `Stop && stall[5] == `NoStop)) begin
        wb_wd    <= `NOPRegAddr;
        wb_wreg  <= `WriteDisable;
        wb_wdata <= `ZeroWord;
        wb_cp0_reg_we           <= `WriteDisable;
        wb_cp0_reg_write_addr   <= 5'b00000;
        wb_cp0_reg_data         <= `ZeroWord;
    end else if (stall[4] == `NoStop) begin
        wb_wd    <= mem_wd;
        wb_wreg  <= mem_wreg;
        wb_wdata <= mem_wdata;
        wb_cp0_reg_we           <= mem_cp0_reg_we;
        wb_cp0_reg_write_addr   <= mem_cp0_reg_write_addr;
        wb_cp0_reg_data         <= mem_cp0_reg_data;
    end    //if
end      //always


endmodule