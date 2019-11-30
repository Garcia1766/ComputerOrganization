`include "defines.sv"

module sram_ctrl(
    // 面向cpu的接口
    input wire          clk, 
    input wire[19:0]    addr_i,     //sram地址
    input wire[`RegBus] data_i,     //写入sram的数据
    input wire          ce_i,       //sram使能信号
    input wire          we_i,       //sram可写信号
    input wire[3:0]     sel_i,      //sram片选
    output wire[31:0]   data_o,    //读出ram的数据

    // 面向sram的接口
    inout wire[`RegBus] sram_data, //sram总线
    output wire[19:0]   sram_addr, //对应的物理地址
    output wire         sram_ce_n, //sram片选使能信号
    output wire         sram_oe_n, //sram输出使能信号
    output wire         sram_we_n, //sram写入使能信号
    output wire[3:0]    sram_be_n  //字节选择信号
);

assign sram_addr = addr_i;                      //总线传给sram的20位地址
assign sram_ce_n = ~ce_i;
assign sram_oe_n = ~(ce_i & (~we_i));           //不可用或者可写的时候可以有输出
assign sram_we_n = ~((~clk) & ce_i & we_i);
assign sram_be_n = (~clk) ? (~sel_i) : 4'b0000;
assign sram_data = (ce_i & we_i)? data_i:32'bz; //可用且可写时，把数据传入bus，否则传入z
assign data_o    = (ce_i & (~we_i)) ? sram_data : 32'h0; //可用但是不可写，则给出sram的数据

endmodule
