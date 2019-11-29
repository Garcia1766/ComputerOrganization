`include "defines.sv"

module regfile(
    input wire clk,
    input wire rst,

    output wire[15:0] reg1,

    //写端口
    input wire              we,
    input wire[`RegAddrBus] waddr,
    input wire[`RegBus]     wdata,

    //读端口1，去除了re1
    input wire[`RegAddrBus] raddr1,
    output reg[`RegBus]     rdata1,

    //读端口2，去除了re2
    input wire[`RegAddrBus] raddr2,
    output reg[`RegBus]     rdata2

);

reg[`RegBus] regs[0:`RegNum-1];

assign reg1 = regs[1][15:0];

// 寄存器写回，唯一的时序逻辑，对应流水线第五阶段的写回
always_ff @ (posedge clk) begin
    if (rst == `RstDisable) begin
        if((we == `WriteEnable) && (waddr != `RegNumLog2'h0)) begin
            regs[waddr] <= wdata;
        end
    end
end

// reg1的读取，去除了读使能的逻辑
always_comb begin
    if(rst == `RstEnable) begin
        rdata1 <= `ZeroWord;
    end else if(raddr1 == `RegNumLog2'h0) begin
        rdata1 <= `ZeroWord;
    end else if((raddr1 == waddr) && (we == `WriteEnable)) begin
        rdata1 <= wdata;
    end else begin
        rdata1 <= regs[raddr1];
    end
end

// reg2的读取，去除了读使能的逻辑
always_comb begin
    if(rst == `RstEnable) begin // 初始化
        rdata2 <= `ZeroWord;
    end else if(raddr2 == `RegNumLog2'h0) begin // 零寄存器
        rdata2 <= `ZeroWord;
    end else if((raddr2 == waddr) && (we == `WriteEnable)) begin // 与回写寄存器相同
        rdata2 <= wdata;
    end else  begin
        rdata2 <= regs[raddr2];
    end
end

endmodule
