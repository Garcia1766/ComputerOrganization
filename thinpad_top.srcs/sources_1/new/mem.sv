`include "defines.sv"

module mem(
    input wire              rst,

    //来自执行阶段的信息
    input wire[`RegAddrBus] wd_i,
    input wire              wreg_i,
    input wire[`RegBus]     wdata_i,

    //送到回写阶段的信息
    output reg[`RegAddrBus] wd_o,
    output reg              wreg_o,
    output reg[`RegBus]     wdata_o
);

// 现阶段mem只是简单地把数据传递下去，等到加上读写内存相关的指令时才增加逻辑
always @ (*) begin
    if(rst == `RstEnable) begin
        wd_o    <= `NOPRegAddr;
        wreg_o  <= `WriteDisable;
        wdata_o <= `ZeroWord;
    end else begin
        wd_o    <= wd_i;
        wreg_o  <= wreg_i;
        wdata_o <= wdata_i;
    end    //if
end      //always


endmodule