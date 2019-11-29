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
    input wire              is_in_delayslot,

    input wire[`RegBus]     inst_i,
    output wire[`AluOpBus]  aluop_o,
    output wire[`RegBus]    mem_addr_o,
    output wire[`RegBus]    reg2_o,

    // 解决连续两条store到同一个地址的冲突
    input wire[`AluOpBus]   last_aluop,
    input wire[`RegBus]     last_mem_addr,
    output wire             stallreq
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
// logic[`RegBus] sum_res;      // 加法结果

// assign reg2_i_mux = (aluop_i == `EXE_SLT_OP) ? (~reg2_i)+1 : reg2_i;
// assign sum_res = reg1_i + reg2_i_mux;
// assign reg1_lt_reg2 = (aluop_i == `EXE_SLT_OP) ?
//                         ((reg1_i[31] && !reg2_i[31]) || (!reg1_i[31] && !reg2_i[31] && sum_res[31]) || (reg1_i[31] && reg2_i[31] && sum_res[31]))
//                         : (reg1_i < reg2_i);


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
            default: begin
            end
        endcase
    end
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