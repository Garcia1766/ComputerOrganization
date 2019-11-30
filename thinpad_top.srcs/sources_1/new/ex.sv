`include "defines.sv"

module ex(
    input wire              rst,

    //输入信息
    input wire[`AluOpBus]   aluop_i,    // 运算的子类型
    input wire[`AluSelBus]  alusel_i,   // 运算的类型
    input wire[`RegBus]     reg1_i,     // 操作数1
    input wire[`RegBus]     reg2_i,     // 操作数2
    input wire[`RegAddrBus] wd_i,       // 目标地址
    input wire              wreg_i,     // 是否写回寄存器

    output reg[`RegAddrBus] wd_o,
    output reg              wreg_o,
    output reg[`RegBus]     wdata_o,

    input wire[`RegBus]     link_addr,
    input wire              is_in_delayslot, //即 is_in_delayslot_i

    input wire[`RegBus]     inst_i,
    output wire[`AluOpBus]  aluop_o,
    output wire[`RegBus]    mem_addr_o,
    output wire[`RegBus]    reg2_o,

    // 解决连续两条store到同一个地址的冲突
    input wire[`AluOpBus]   last_aluop,
    input wire[`RegBus]     last_mem_addr,
    output wire             stallreq,

    // 仿存阶段的指令是否要写CP0中的寄存器
    input wire              mem_cp0_reg_we,
    input wire[4:0]         mem_cp0_reg_write_addr,
    input wire[`RegBus]     mem_cp0_reg_data,
    // 回写阶段的指令是否要写CP0中的寄存器
    input wire              wb_cp0_reg_we,
    input wire[4:0]         wb_cp0_reg_write_addr,
    input wire[`RegBus]     wb_cp0_reg_data,
    // 与CP0直接相连，用于读取其中指定寄存器的值
    output reg[4:0]         cp0_reg_read_addr_o,
    input wire[`RegBus]     cp0_reg_data_i,
    // 向流水线下一级传递，用于写CP0中的指定寄存器
    output reg              cp0_reg_we_o,
    output reg[4:0]         cp0_reg_write_addr_o,
    output reg[`RegBus]     cp0_reg_data_o,

    //异常相关
    input wire[31:0]        excepttype_i,
    input wire[`RegBus]     current_inst_address_i,
    output wire[31:0]       excepttype_o,
    output wire             is_in_delayslot_o,
    output wire[`RegBus]    current_inst_address_o
);

wire[`RegBus] addr_o;
assign aluop_o = aluop_i;
assign addr_o = reg1_i + {{16{inst_i[15]}}, inst_i[15:0]};
assign mem_addr_o = addr_o;
assign reg2_o = reg2_i;

// 算数&逻辑指令的结果
reg[`RegBus] arithout;
reg[`RegBus] moveres;

assign stallreq = (((last_aluop == `EXE_SB_OP) || (last_aluop == `EXE_SW_OP)) &&
                    ((aluop_i == `EXE_SB_OP) || (aluop_i == `EXE_SW_OP) || (aluop_i == `EXE_LB_OP)
                    || (aluop_i == `EXE_LH_OP) || (aluop_i == `EXE_LW_OP))) ? 1'b1 : 1'b0;

// slt相关的逻辑，留作备考
// // 一些中间结果
// logic reg1_lt_reg2; // reg1是否小于reg2
// logic[`RegBus] reg2_i_mux;   // reg2的补码
// logic[`RegBus]  sum_res;    // 加法结果
// logic           ov_sum;     // 是否溢出

// assign reg2_i_mux = (aluop_i == `EXE_SLT_OP) ? (~reg2_i)+1 : reg2_i;
// assign sum_res = reg1_i + reg2_i_mux;
// assign reg1_lt_reg2 = (aluop_i == `EXE_SLT_OP) ?
//                         ((reg1_i[31] && !reg2_i[31]) || (!reg1_i[31] && !reg2_i[31] && sum_res[31]) || (reg1_i[31] && reg2_i[31] && sum_res[31]))
//                         : (reg1_i < reg2_i);

//异常相关
reg trapassert; //是否有自陷异常
reg ovassert;   //是否有溢出异常
//执行阶段输出的异常信息就是译码阶段的异常信息加上自陷异常、溢出异常，第10位表示是否有自陷异常，第11位表示是否有溢出异常
assign excepttype_o = {excepttype_i[31:12], ovassert, trapassert, excepttype_i[9:8], 8'h00};
assign is_in_delayslot_o = is_in_delayslot;
assign current_inst_address_o = current_inst_address_i;

//计算以下4个变量的值，判断有无溢出异常
//assign sum_res = reg1_i + reg2_i;
//assign ov_sum  = ((!reg1_i[31] && !reg2_i[31]) && sum_res[31]) || ((reg1_i[31] && reg2_i[31]) && !sum_res[31]);

// 算数运算的组合逻辑
always_comb begin
    if(rst == `RstEnable) begin
        arithout <= `ZeroWord;
    end else begin
        case (aluop_i)
            `EXE_OR_OP : begin arithout <= reg1_i | reg2_i; end
            `EXE_AND_OP: begin arithout <= reg1_i & reg2_i; end
            `EXE_XOR_OP: begin arithout <= reg1_i ^ reg2_i; end
            `EXE_SLL_OP: begin arithout <= reg2_i << reg1_i[4:0]; end
            `EXE_SRL_OP: begin arithout <= reg2_i >> reg1_i[4:0]; end
            `EXE_ADD_OP: begin arithout <= reg1_i + reg2_i; end
            // SLT指令的部分
            // `EXE_SLT_OP, `EXE_SLTU_OP: begin
            //     arithout <= reg1_lt_reg2;
            // end
            `EXE_CLZ_OP: begin  // 计算前导零的数量
                arithout <=
                reg1_i[31] ? 0  : reg1_i[30] ? 1  : reg1_i[29] ? 2  :
                reg1_i[28] ? 3  : reg1_i[27] ? 4  : reg1_i[26] ? 5  :
                reg1_i[25] ? 6  : reg1_i[24] ? 7  : reg1_i[23] ? 8  :
                reg1_i[22] ? 9  : reg1_i[21] ? 10 : reg1_i[20] ? 11 :
                reg1_i[19] ? 12 : reg1_i[18] ? 13 : reg1_i[17] ? 14 :
                reg1_i[16] ? 15 : reg1_i[15] ? 16 : reg1_i[14] ? 17 :
                reg1_i[13] ? 18 : reg1_i[12] ? 19 : reg1_i[11] ? 20 :
                reg1_i[10] ? 21 : reg1_i[9]  ? 22 : reg1_i[8]  ? 23 :
                reg1_i[7]  ? 24 : reg1_i[6]  ? 25 : reg1_i[5]  ? 26 :
                reg1_i[4]  ? 27 : reg1_i[3]  ? 28 : reg1_i[2]  ? 29 :
                reg1_i[1]  ? 30 : reg1_i[0]  ? 31 : 32;
            end
            default: begin arithout <= `ZeroWord; end
        endcase
    end    //if
end      //always

// move运算的组合逻辑
always_comb begin
    if(rst == `RstEnable) begin
        moveres <= `ZeroWord;
    end else begin
        moveres <= `ZeroWord;
        case(aluop_i)
            `EXE_MOVN_OP: begin
                moveres <= reg1_i;
            end
            `EXE_MFC0_OP: begin
                //要从CP0中读取的寄存器的地址
                cp0_reg_read_addr_o <= inst_i[15:11];
                //读取到的CP0中指定寄存器的值
                moveres <= cp0_reg_data_i;
                //判断是否存在数据相关
                if (mem_cp0_reg_we == `WriteEnable &&
                    mem_cp0_reg_write_addr == inst_i[15:11]) begin //与仿存阶段存在数据相关
                    moveres <= mem_cp0_reg_data;
                end else if (wb_cp0_reg_we == `WriteEnable &&
                            wb_cp0_reg_write_addr == inst_i[15:11]) begin //与回写阶段存在数据相关
                    moveres <= wb_cp0_reg_data;
                end
            end
            default: begin
            end
        endcase
    end
end

// 给出mtc0指令执行结果
always_comb begin
    if (rst == `RstEnable) begin
        cp0_reg_write_addr_o <= 5'b00000;
        cp0_reg_we_o         <= `WriteDisable;
        cp0_reg_data_o       <= `ZeroWord;        
    end else if (aluop_i == `EXE_MTC0_OP) begin
        cp0_reg_write_addr_o <= inst_i[15:11];
        cp0_reg_we_o         <= `WriteEnable;
        cp0_reg_data_o       <= reg1_i;
    end else begin
        cp0_reg_write_addr_o <= 5'b00000;
        cp0_reg_we_o         <= `WriteDisable;
        cp0_reg_data_o       <= `ZeroWord;
    end
end

//无自陷异常
always_comb begin
    trapassert <= `TrapNotAssert;
end

//无溢出异常
always_comb begin
    ovassert <= 1'b0;
end

// 输出的组合逻辑
always_comb begin
    wd_o <= wd_i;
    wreg_o <= wreg_i;
    case (alusel_i)
    `EXE_RES_ARITH: begin
        wdata_o <= arithout;
    end
    `EXE_RES_MOVE: begin
        wdata_o <= moveres;
    end
    `EXE_RES_JB: begin
        wdata_o <= link_addr;
    end
    default: begin
        wdata_o <= `ZeroWord;
    end
    endcase
end

endmodule