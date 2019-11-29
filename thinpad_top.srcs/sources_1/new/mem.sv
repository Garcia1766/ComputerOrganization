`include "defines.sv"

module mem(
    input wire              rst,

    //来自ex阶段的信息
    input wire[`RegAddrBus] wd_i,
    input wire              wreg_i,
    input wire[`RegBus]     wdata_i,

    //送到wb阶段的信息
    output reg[`RegAddrBus] wd_o,
    output reg              wreg_o,
    output reg[`RegBus]     wdata_o,

    // load/store相关信号
    input wire[`AluOpBus]   aluop_i,
    input wire[`RegBus]     mem_addr_i,
    input wire[`RegBus]     reg2_i,
    input wire[`RegBus]     mem_data_i,
    output reg[`RegBus]     mem_addr_o,
    output reg              mem_we_o,
    output reg[3:0]         mem_sel_o,
    output reg[`RegBus]     mem_data_o,
    output reg              mem_ce_o,

    //cp0相关信号
    input wire              cp0_reg_we_i,
    input wire[4:0]         cp0_reg_write_addr_i,
    input wire[`RegBus]     cp0_reg_data_i,
    output reg              cp0_reg_we_o,
    output reg[4:0]         cp0_reg_write_addr_o,
    output reg[`RegBus]     cp0_reg_data_o,

    //异常相关
    //来自ex
    input wire[31:0]        excepttype_i,
    input wire              is_in_delayslot_i,
    input wire[`RegBus]     current_inst_address_i,
    //来自CP0
    input wire[`RegBus]     cp0_status_i,
    input wire[`RegBus]     cp0_cause_i,
    input wire[`RegBus]     cp0_epc_i,
    //来自wb，是回写阶段的指令对CP0中寄存器的写信息，用来检测数据相关
    input wire              wb_cp0_reg_we,
    input wire[4:0]         wb_cp0_reg_write_addr,
    input wire[`RegBus]     wb_cp0_reg_data,
    //输出至CP0
    output reg[31:0]        excepttype_o,
    output wire             is_in_delayslot_o, //仿存阶段的指令是否是延迟槽指令
    output wire[`RegBus]    current_inst_address_o, //仿存阶段指令的地址
    //输出至ctrl模块
    output wire[`RegBus]    cp0_epc_o
);

wire[`RegBus]   zero32;
reg[`RegBus]    cp0_status; //保存CP0中Status寄存器的最新值
reg[`RegBus]    cp0_cause;  //保存CP0中Cause寄存器的最新值
reg[`RegBus]    cp0_epc;    //保存CP0中EPC寄存器的最新值
reg             mem_we;

assign zero32 = `ZeroWord;
assign is_in_delayslot_o = is_in_delayslot_i;
assign current_inst_address_o = current_inst_address_i;

always_comb begin
    if(rst == `RstEnable) begin
        wd_o    <= `NOPRegAddr;
        wreg_o  <= `WriteDisable;
        wdata_o <= `ZeroWord;
        mem_addr_o <= `ZeroWord;
        mem_we_o <= `WriteDisable;
        mem_sel_o <= 4'b0000;
        mem_data_o <= `ZeroWord;
        mem_ce_o <= `ChipDisable;
        cp0_reg_we_o <= `WriteDisable;
        cp0_reg_write_addr_o <= 5'b00000;
        cp0_reg_data_o <= `ZeroWord;
    end else begin
        wd_o    <= wd_i;
        wreg_o  <= wreg_i;
        wdata_o <= wdata_i;
        mem_we_o <= `WriteDisable;
        mem_addr_o <= `ZeroWord;
        mem_sel_o <= 4'b1111;
        mem_ce_o <= `ChipDisable;
        mem_data_o <= `ZeroWord;
        //将对CP0中寄存器的写信息传递到流水线下一级
        cp0_reg_we_o <= cp0_reg_we_i;
        cp0_reg_write_addr_o <= cp0_reg_write_addr_i;
        cp0_reg_data_o <= cp0_reg_data_i;
        case (aluop_i)
            `EXE_LB_OP: begin
                mem_addr_o <= mem_addr_i;
                mem_ce_o <= `ChipEnable;
                case (mem_addr_i[1:0])
                    2'b11: begin
                        wdata_o <= {{24{mem_data_i[31]}},mem_data_i[31:24]};
                        mem_sel_o <= 4'b1000;
                    end
                    2'b10: begin
                        wdata_o <= {{24{mem_data_i[23]}},mem_data_i[23:16]};
                        mem_sel_o <= 4'b0100;
                    end
                    2'b01: begin
                        wdata_o <= {{24{mem_data_i[15]}},mem_data_i[15:8]};
                        mem_sel_o <= 4'b0010;
                    end
                    2'b00: begin
                        wdata_o <= {{24{mem_data_i[7]}},mem_data_i[7:0]};
                        mem_sel_o <= 4'b0001;
                    end
                    default: begin
                        wdata_o <= `ZeroWord;
                    end
                endcase
            end
            `EXE_LH_OP: begin
                mem_addr_o <= mem_addr_i;
                mem_ce_o <= `ChipEnable;
                case (mem_addr_i[1:0])
                    2'b10: begin
                        wdata_o <= {{16{mem_data_i[31]}},mem_data_i[31:16]};
                        mem_sel_o <= 4'b1100;
                    end
                    2'b00: begin
                        wdata_o <= {{16{mem_data_i[15]}},mem_data_i[15:0]};
                        mem_sel_o <= 4'b0011;
                    end
                    default: begin
                        wdata_o <= `ZeroWord;
                    end
                endcase
            end
            `EXE_LW_OP: begin
                mem_addr_o <= mem_addr_i;
                mem_ce_o <= `ChipEnable;
                wdata_o <= mem_data_i;
                mem_sel_o <= 4'b1111;
            end
            `EXE_SB_OP: begin
                mem_addr_o <= mem_addr_i;
                mem_we_o <= `WriteEnable;
                mem_data_o <= {reg2_i[7:0],reg2_i[7:0],reg2_i[7:0],reg2_i[7:0]};
                mem_ce_o <= `ChipEnable;
                case (mem_addr_i[1:0])
                    2'b11:    begin
                        mem_sel_o <= 4'b1000;
                    end
                    2'b10:    begin
                        mem_sel_o <= 4'b0100;
                    end
                    2'b01:    begin
                        mem_sel_o <= 4'b0010;
                    end
                    2'b00:    begin
                        mem_sel_o <= 4'b0001;
                    end
                    default:    begin
                        mem_sel_o <= 4'b0000;
                    end
                endcase
            end
            `EXE_SW_OP:    begin
                mem_addr_o <= mem_addr_i;
                mem_we_o <= `WriteEnable;
                mem_data_o <= reg2_i;
                mem_sel_o <= 4'b1111;
                mem_ce_o <= `ChipEnable;
            end
            default: begin
            end
        endcase
    end    //if
end      //always

/* 第一步：得到CP0中寄存器的最新值 */
// 得到CP0中Status寄存器的最新值，步骤如下：
// 判断当前处于回写阶段的指令是否要写CP0中Status寄存器，若是，则要写入的值就是Status的最新值；
// 否则通过cp0_status_i传入的来自CP0的数据就是最新值
always_comb begin
    if (rst == `RstEnable) begin
        cp0_status <= `ZeroWord;
    end else if ((wb_cp0_reg_we == `WriteEnable) && (wb_cp0_reg_write_addr == `CP0_REG_STATUS)) begin
        cp0_status <= wb_cp0_reg_data;
    end else begin
        cp0_status <= cp0_status_i;
    end
end

// 得到CP0中EPC寄存器的最新值，步骤如下：
// 判断当前处于回写阶段的指令是否要写CP0中EPC寄存器，若是，则要写入的值就是EPC的最新值；
// 否则通过cp0_epc_i传入的来自CP0的数据就是最新值
always_comb begin
    if (rst == `RstEnable) begin
        cp0_epc <= `ZeroWord;
    end else if ((wb_cp0_reg_we == `WriteEnable) && (wb_cp0_reg_write_addr == `CP0_REG_EPC)) begin
        cp0_epc <= wb_cp0_reg_data;
    end else begin
        cp0_epc <= cp0_epc_i;
    end
end

assign cp0_epc_o = cp0_epc;

// 得到CP0中Cause寄存器的最新值，步骤如下：
// 判断当前处于回写阶段的指令是否要写CP0中Cause寄存器，若是，则要写入的值就是Cause的最新值；（注意，Cause寄存器只有几个字段可写）
// 否则通过cp0_cause_i传入的来自CP0的数据就是最新值
always_comb begin
    if (rst == `RstEnable) begin
        cp0_cause <= `ZeroWord;
    end else if ((wb_cp0_reg_we == `WriteEnable) && (wb_cp0_reg_write_addr == `CP0_REG_CAUSE)) begin
        cp0_cause[9:8]  <= wb_cp0_reg_data[9:8];// IP[1:0]
        cp0_cause[22]   <= wb_cp0_reg_data[22]; // WP
        cp0_cause[23]   <= wb_cp0_reg_data[23]; // IV
    end else begin
        cp0_cause <= cp0_cause_i;
    end
end

/* 第二步：给出最终异常类型 */
always_comb begin
    if(rst == `RstEnable) begin
        excepttype_o <= `ZeroWord;
    end else begin
        excepttype_o <= `ZeroWord;

        if(current_inst_address_i != `ZeroWord) begin
            if( ((cp0_cause[15:8] & cp0_status[15:8]) != 8'h00) && 
                (cp0_status[1] == 1'b0) && 
                (cp0_status[0] == 1'b1)) begin
                excepttype_o <= 32'h00000001;        //interrupt
            end else if(excepttype_i[8] == 1'b1) begin
                excepttype_o <= 32'h00000008;        //syscall
            end else if(excepttype_i[9] == 1'b1) begin
                excepttype_o <= 32'h0000000a;        //inst_invalid
            end else if(excepttype_i[10] ==1'b1) begin
                excepttype_o <= 32'h0000000d;        //trap
            end else if(excepttype_i[11] == 1'b1) begin
                excepttype_o <= 32'h0000000c;        //ov
            end else if(excepttype_i[12] == 1'b1) begin
                excepttype_o <= 32'h0000000e;        //eret
            end
        end
            
    end
end

/* 第三步：给出对数据储存器的写操作 */
// 如果发生异常，需要取消对数据储存器的写操作
assign mem_we_o = mem_we & (~(|excepttype_o));

endmodule