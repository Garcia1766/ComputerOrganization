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

    output logic            uart_rdn,               //读串口信号，低有效
    output logic            uart_wrn,               //写串口信号，低有效
    input logic             uart_dataready,         //串口数据准备好
    input logic             uart_tbre,              //发送数据标志
    input logic             uart_tsre,              //数据发送完毕标志
    inout wire[31:0]        uart_data,

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

// ram读写的相关信号
reg                 sram_ce_o;
reg                 sram_we_o;
reg[19:0]           sram_addr_o;
reg[`InstBus]       sram_data_o;    //向sram写入的数据
reg[3:0]            sram_sel_o;
reg[`InstBus]       sram_data_i;    //从sram读出的数据
reg                 sram_no;        //0--baseram, 1--extraram

reg[31:0] uart_data_buff;
assign uart_data = ((rst == `RstDisable) && (mem_ce_i == 1'b1) && (mem_addr_i == 32'hBFD003F8) && (mem_we_i == 1'b1)) ? uart_data_buff : 32'bz;

always_comb begin
    if_data_o   <= `ZeroWord;
    mem_data_o  <= `ZeroWord;
    sram_ce_o   <= 1'b0;
    sram_we_o   <= 1'b0;
    sram_addr_o <= `ZeroWord;
    sram_no     <= 1'b0;
    sram_data_o <= `ZeroWord;
    sram_sel_o  <= 4'b0000;
    uart_wrn    <= 1'b1;
    uart_rdn    <= 1'b1;
    if (rst == `RstEnable) begin
        if_data_o <= `ZeroWord;
        mem_data_o <= `ZeroWord;
    end else begin
        if (mem_ce_i == 1'b1) begin
            if (mem_addr_i == 32'hBFD003F8) begin // UART串口
                if (mem_we_i == 1'b1) begin //写串口
                    if (clk == 1'b0) begin
                        uart_wrn <= 1'b0;
                    end else begin
                        uart_wrn <= 1'b1;
                    end
                    uart_data_buff <= mem_data_i;
                end else begin    //读串口
                    uart_rdn <= 1'b0;
                    mem_data_o <= {24'b0, uart_data[7:0]};
                end
            end else if (mem_addr_i == 32'hBFD003FC) begin // UART状态
                mem_data_o <= {30'b0, uart_dataready, uart_tsre&uart_tbre};
            end else begin
                sram_ce_o   <= 1'b1;
                sram_we_o   <= mem_we_i;
                sram_addr_o <= mem_addr_i[21:2];
                sram_no     <= mem_addr_i[22];
                sram_data_o <= mem_data_i;
                sram_sel_o  <= mem_sel_i;
                mem_data_o  <= sram_data_i;
            end
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
    sram1_addr_o    <= 32'b0;
    sram1_data_o    <= 32'b0;
    sram1_sel_o     <= 4'b0;
    sram2_ce_o      <= 1'b0;
    sram2_we_o      <= 1'b0;
    sram2_addr_o    <= 32'b0;
    sram2_data_o    <= 32'b0;
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
