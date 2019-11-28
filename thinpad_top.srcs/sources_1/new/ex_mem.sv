`include "defines.sv"

module ex_mem(
    input wire              clk,
    input wire              rst,

    //来自ex阶段的信息
    input wire[`RegAddrBus] ex_wd,
    input wire              ex_wreg,
    input wire[`RegBus]     ex_wdata,

    input wire[5:0]         stall,

    //送到mem阶段的信息
    output reg[`RegAddrBus] mem_wd,
    output reg              mem_wreg,
    output reg[`RegBus]     mem_wdata,

    // load/store需要的相关信息
    input wire[`AluOpBus]   ex_aluop,
    input wire[`RegBus]     ex_mem_addr,
    input wire[`RegBus]     ex_reg2,
    output reg[`AluOpBus]   mem_aluop,
    output reg[`RegBus]     mem_mem_addr,
    output reg[`RegBus]     mem_reg2,

    //cp0相关信息
    input wire              ex_cp0_reg_we,
    input wire[4:0]         ex_cp0_reg_write_addr,
    input wire[`RegBus]     ex_cp0_reg_data,
    output reg              mem_cp0_reg_we,
    output reg[4:0]         mem_cp0_reg_write_addr,
    output reg[`RegBus]     mem_cp0_reg_data
);

always_ff @ (posedge clk) begin
    if(rst == `RstEnable || (stall[3] == `Stop && stall[4] == `NoStop)) begin
        mem_wd <= `NOPRegAddr;
        mem_wreg <= `WriteDisable;
        mem_wdata <= `ZeroWord;
        mem_aluop <= `EXE_NOP_OP;
        mem_mem_addr <= `ZeroWord;
        mem_reg2 <= `ZeroWord;
        mem_cp0_reg_we <= `WriteDisable;
        mem_cp0_reg_write_addr <= 5'b00000;
        mem_cp0_reg_data <= `ZeroWord;
    end else if (stall[3] == `NoStop) begin
        mem_wd <= ex_wd;
        mem_wreg <= ex_wreg;
        mem_wdata <= ex_wdata;
        mem_aluop <= ex_aluop;
        mem_mem_addr <= ex_mem_addr;
        mem_reg2 <= ex_reg2;
        mem_cp0_reg_we <= ex_cp0_reg_we;
        mem_cp0_reg_write_addr <= ex_cp0_reg_write_addr;
        mem_cp0_reg_data <= ex_cp0_reg_data;
    end    //if
end      //always

endmodule