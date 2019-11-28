`include "defines.sv"


module bus_ctrl(
    input wire          clk,
    input wire          rst,

    input wire                  if_ce_i,            //pc发送来的使能信号
    input wire[`InstAddrBus]    if_addr_i,          //pc要读取的指令地址
    output reg[`InstBus]        if_data_o,          //给if/id模块的指令

    input wire                  mem_ce_i,           //mem发送来的使能信号
    input wire[`InstBus]        mem_data_i,         //mem发送来的data
    input wire[`InstAddrBus]    mem_addr_i,         //mem发送来的地址
    input wire                  mem_we_i,           //mem发送来的写使能
    input wire[3:0]             mem_sel_i,          //mem发送来的片选信号
    output reg[`InstBus]        mem_data_o,         //读出的32位数据

    output reg              sram1_ce_o,         //base sram使能信号
    output reg              sram1_we_o,         //base sram是否写入
    output reg[19:0]        sram1_addr_o,       //base sram地址
    output reg[`InstBus]    sram1_data_o,       //向base sram写入的数据
    output reg[3:0]         sram1_sel_o,        //base sram片选信号
    input wire[`InstBus]    sram1_data_i,       //从base sram读出的数据

    output reg              sram2_ce_o,         //extent sram使能信号
    output reg              sram2_we_o,         //extent sram是否写入
    output reg[19:0]        sram2_addr_o,       //extent sram地址
    output reg[`InstBus]    sram2_data_o,       //向extent sram写入的数据
    output reg[3:0]         sram2_sel_o,        //extent ram片选信号
    input wire[`InstBus]    sram2_data_i        //从extend sram读出的数据
);

reg                 sram_ce_o;
reg                 sram_we_o;
reg[19:0]           sram_addr_o;
reg[`InstBus]       sram_data_o;    //暂存要向sram写入的数据
reg[3:0]            sram_sel_o;
reg[`InstBus]       sram_data_i;    //暂存从sram读出的数据
reg                 sram_no;        //0--baseram, 1--extraram

always_comb begin
    if_data_o   <= `ZeroWord;
    mem_data_o  <= `ZeroWord;
    sram_ce_o   <= 1'b0;
    sram_we_o   <= 1'b0;
    sram_addr_o <= `ZeroWord;
    sram_no     <= 1'b0;
    sram_data_o <= `ZeroWord;
    sram_sel_o  <= 4'b0000;
    if (rst == `RstEnable) begin
        if_data_o <= `ZeroWord;
        mem_data_o <= `ZeroWord;
    end else begin
        if (mem_ce_i == 1'b1) begin
            sram_ce_o   <= 1'b1;
            sram_we_o   <= mem_we_i;
            sram_addr_o <= mem_addr_i[21:2];
            sram_no     <= mem_addr_i[22];
            sram_data_o <= mem_data_i;
            sram_sel_o  <= mem_sel_i;
            mem_data_o  <= sram_data_i;
        end else if (if_ce_i == 1'b1) begin
            sram_ce_o   <= 1'b1;
            sram_we_o   <= 1'b0;
            sram_addr_o <= if_addr_i[21:2];
            sram_no     <= if_addr_i[22];
            sram_data_o <= `ZeroWord;
            sram_sel_o  <= 4'b1111;
            if_data_o   <= sram_data_i;
        end else begin
            sram_ce_o <= 1'b0;
            sram_we_o <= 1'b0;
            sram_addr_o <= 20'b0;
            sram_data_o <= `ZeroWord;
            sram_sel_o <= 4'h0;
            mem_data_o <= `ZeroWord;
        end
    end
end

always_comb begin
    sram1_ce_o      <= 1'b0;
    sram1_we_o      <= 1'b0;
    sram1_addr_o    <= `ZeroWord;
    sram1_data_o    <= `ZeroWord;
    sram1_sel_o     <= 4'b0;
    sram2_ce_o      <= 1'b0;
    sram2_we_o      <= 1'b0;
    sram2_addr_o    <= `ZeroWord;
    sram2_data_o    <= `ZeroWord;
    sram2_sel_o     <= 4'b0;
    if (sram_no == 1'b0) begin  //0x8......
        sram1_ce_o      <= sram_ce_o;
        sram1_we_o      <= sram_we_o;
        sram1_addr_o    <= sram_addr_o;
        sram1_data_o    <= sram_data_o;
        sram1_sel_o     <= sram_sel_o;
        sram_data_i     <= sram1_data_i;
    end else begin              //0x0......
        sram2_ce_o      <= sram_ce_o;
        sram2_we_o      <= sram_we_o;
        sram2_addr_o    <= sram_addr_o;
        sram2_data_o    <= sram_data_o;
        sram2_sel_o     <= sram_sel_o;
        sram_data_i     <= sram2_data_i;
    end
end

endmodule
