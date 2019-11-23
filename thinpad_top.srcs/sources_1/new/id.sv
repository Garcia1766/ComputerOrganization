`include "defines.sv"

module id(
    input wire                rst,
    input wire[`InstAddrBus]  pc_i,         // pc地址
    input wire[`InstBus]      inst_i,       // 指令
    input wire[`RegBus]       reg1_data_i,  // 寄存器1的读取数据
    input wire[`RegBus]       reg2_data_i,  // 寄存器2的读取数据

    // ex阶段的前传数据
    input wire                ex_wreg_i,
    input wire[`RegBus]       ex_wdata_i,
    input wire[`RegAddrBus]   ex_wd_i,

    // mem阶段的前传数据
    input wire                mem_wreg_i,
    input wire[`RegBus]       mem_wdata_i,
    input wire[`RegAddrBus]   mem_wd_i,

    // 传递到regfile的信号，去除了两个读使能
    output reg[`RegAddrBus]   reg1_addr_o,  // reg1读地址
    output reg[`RegAddrBus]   reg2_addr_o,  // reg2读地址

    // 传递到ex阶段的信号
    output reg[`AluOpBus]     aluop_o,      // 运算的子类型（指令后六位）
    output reg[`AluSelBus]    alusel_o,     // 运算的类型（指令的前六位）
    output reg[`RegBus]       reg1_o,       // 操作数1
    output reg[`RegBus]       reg2_o,       // 操作数2
    output reg[`RegAddrBus]   wd_o,         // 目标寄存器地址
    output reg                wreg_o        // 是否要写回寄存器
);

wire[5:0] op  = inst_i[31:26];
wire[4:0] op2 = inst_i[10:6];
wire[5:0] op3 = inst_i[5:0];
wire[4:0] op4 = inst_i[20:16];
reg[`RegBus] imm;   // 立即数
reg instvalid;      // 指令无效，方便调试

// 控制信号
logic reg1_imm;    // reg1是否取立即数
logic reg2_imm;    // reg2是否取立即数

// 译码的组合逻辑
always_comb begin
    if (rst == `RstEnable) begin
        aluop_o     <= `EXE_NOP_OP;
        alusel_o    <= `EXE_RES_NOP;
        wd_o        <= `NOPRegAddr;
        wreg_o      <= `WriteDisable;
        instvalid   <= `InstValid;
        reg1_imm    <= 1'b1;
        reg2_imm    <= 1'b1;
        reg1_addr_o <= `NOPRegAddr;
        reg2_addr_o <= `NOPRegAddr;
        imm         <= `ZeroWord;
    end else begin
        aluop_o     <= `EXE_NOP_OP;
        alusel_o    <= `EXE_RES_NOP;
        wd_o        <= inst_i[15:11];
        wreg_o      <= `WriteDisable;
        instvalid   <= `InstInvalid;
        reg1_imm    <= 1'b1;
        reg2_imm    <= 1'b1;
        reg1_addr_o <= inst_i[25:21];
        reg2_addr_o <= inst_i[20:16];
        imm         <= `ZeroWord;
        case (op)
            `EXE_ORI: begin
                wreg_o      <= `WriteEnable;          // 需要写回寄存器
                aluop_o     <= `EXE_OR_OP;            // 子类型是or运算
                alusel_o    <= `EXE_RES_ARITH;        // 类型是逻辑运算
                reg1_imm    <= 1'b0;                  // reg1不是立即数
                reg2_imm    <= 1'b1;                  // reg2是立即数
                imm         <= {16'h0, inst_i[15:0]}; // 立即数
                wd_o        <= inst_i[20:16];         // 目标寄存器地址
                instvalid   <= `InstValid;
            end
            `EXE_ANDI: begin
                wreg_o      <= `WriteEnable;
                aluop_o     <= `EXE_AND_OP;
                alusel_o    <= `EXE_RES_ARITH;
                reg1_imm    <= 1'b0;
                reg2_imm    <= 1'b1;
                imm         <= {16'h0, inst_i[15:0]};
                wd_o        <= inst_i[20:16];
                instvalid   <= `InstValid;
            end
            `EXE_XORI: begin
                wreg_o      <= `WriteEnable;
                aluop_o     <= `EXE_XOR_OP;
                alusel_o    <= `EXE_RES_ARITH;
                reg1_imm    <= 1'b0;
                reg2_imm    <= 1'b1;
                imm         <= {16'h0, inst_i[15:0]};
                wd_o        <= inst_i[20:16];
                instvalid   <= `InstValid;
            end
            `EXE_LUI: begin
                wreg_o      <= `WriteEnable;
                aluop_o     <= `EXE_OR_OP;
                alusel_o    <= `EXE_RES_ARITH;
                reg1_imm    <= 1'b0;
                reg2_imm    <= 1'b1;
                imm         <= {inst_i[15:0], 16'h0};
                wd_o        <= inst_i[20:16];
                instvalid   <= `InstValid;
            end
            `EXE_ADDIU: begin
                wreg_o      <= `WriteEnable;
                aluop_o     <= `EXE_ADD_OP;
                alusel_o    <= `EXE_RES_ARITH;
                reg1_imm    <= 1'b0;
                reg2_imm    <= 1'b1;
                imm         <= {16'h0, inst_i[15:0]};
                wd_o        <= inst_i[20:16];
                instvalid   <= `InstValid;
            end
            // 可能会考的指令
            // `EXE_SLTI: begin
            //     wreg_o      <= `WriteEnable;
            //     aluop_o     <= `EXE_SLT_OP;
            //     alusel_o    <= `EXE_RES_ARITH;
            //     reg1_imm    <= 1'b0;
            //     reg2_imm    <= 1'b1;
            //     imm         <= {{16{inst_i[15]}}, inst_i[15:0]};
            //     wd_o        <= inst_i[20:16];
            //     instvalid   <= `InstValid;
            // end
            // `EXE_SLTIU: begin
            //     wreg_o      <= `WriteEnable;
            //     aluop_o     <= `EXE_SLTU_OP;
            //     alusel_o    <= `EXE_RES_ARITH;
            //     reg1_imm    <= 1'b0;
            //     reg2_imm    <= 1'b1;
            //     imm         <= {{16{inst_i[15]}}, inst_i[15:0]};
            //     wd_o        <= inst_i[20:16];
            //     instvalid   <= `InstValid;
            // end
            `EXE_SPECIAL: begin
                case (op3)
                    `EXE_AND: begin
                        wreg_o      <= `WriteEnable;
                        aluop_o     <= `EXE_AND_OP;
                        alusel_o    <= `EXE_RES_ARITH;
                        reg1_imm    <= 1'b0;
                        reg2_imm    <= 1'b0;
                        instvalid   <= `InstValid;
                    end
                    `EXE_OR: begin
                        wreg_o      <= `WriteEnable;
                        aluop_o     <= `EXE_OR_OP;
                        alusel_o    <= `EXE_RES_ARITH;
                        reg1_imm    <= 1'b0;
                        reg2_imm    <= 1'b0;
                        instvalid   <= `InstValid;
                    end
                    `EXE_XOR: begin
                        wreg_o      <= `WriteEnable;
                        aluop_o     <= `EXE_XOR_OP;
                        alusel_o    <= `EXE_RES_ARITH;
                        reg1_imm    <= 1'b0;
                        reg2_imm    <= 1'b0;
                        instvalid   <= `InstValid;
                    end
                    `EXE_SLL: begin
                        wreg_o      <= `WriteEnable;
                        aluop_o     <= `EXE_SLL_OP;
                        alusel_o    <= `EXE_RES_ARITH;
                        reg1_imm    <= 1'b1;
                        reg2_imm    <= 1'b0;
                        imm[4:0]    <= inst_i[10:6];
                        instvalid   <= `InstValid;
                    end
                    `EXE_SRL: begin
                        wreg_o      <= `WriteEnable;
                        aluop_o     <= `EXE_SRL_OP;
                        alusel_o    <= `EXE_RES_ARITH;
                        reg1_imm    <= 1'b1;
                        reg2_imm    <= 1'b0;
                        imm[4:0]    <= inst_i[10:6];
                        instvalid   <= `InstValid;
                    end
                    `EXE_MOVN: begin
                        wreg_o      <= (reg2_o != `ZeroWord) ? `WriteEnable : `WriteDisable;
                        aluop_o     <= `EXE_MOVN_OP;
                        alusel_o    <= `EXE_RES_MOVE;
                        reg1_imm    <= 1'b0;
                        reg2_imm    <= 1'b0;
                        instvalid   <= `InstValid;
                    end
                    `EXE_ADDU: begin
                        wreg_o      <= `WriteEnable;
                        aluop_o     <= `EXE_ADD_OP;
                        alusel_o    <= `EXE_RES_ARITH;
                        reg1_imm    <= 1'b0;
                        reg2_imm    <= 1'b0;
                        instvalid   <= `InstValid;
                    end
                    // 可能会考的指令
                    // `EXE_SLT: begin
                    //     wreg_o      <= `WriteEnable;
                    //     aluop_o     <= `EXE_SLT_OP;
                    //     alusel_o    <= `EXE_RES_ARITH;
                    //     reg1_imm    <= 1'b0;
                    //     reg2_imm    <= 1'b0;
                    //     instvalid   <= `InstValid;
                    // end
                    // `EXE_SLTU: begin
                    //     wreg_o      <= `WriteEnable;
                    //     aluop_o     <= `EXE_SLTU_OP;
                    //     alusel_o    <= `EXE_RES_ARITH;
                    //     reg1_imm    <= 1'b0;
                    //     reg2_imm    <= 1'b0;
                    //     instvalid   <= `InstValid;
                    // end
                    default: begin
                    end
                endcase
            end
            `EXE_SPECIAL2: begin
                case (op3)
                    `EXE_CLZ: begin
                        wreg_o      <= `WriteEnable;
                        aluop_o     <= `EXE_CLZ_OP;
                        alusel_o    <= `EXE_RES_ARITH;
                        reg1_imm    <= 1'b0;
                        reg2_imm    <= 1'b1;
                        instvalid   <= `InstValid;
                    end
                    default: begin
                    end
                endcase
            end
            default: begin
            end
        endcase    //case op
    end    //if
end    //always

// 操作数1输出选择
always_comb begin
    if(rst == `RstEnable) begin
        reg1_o <= `ZeroWord;    // 复位时的值
    end else if (reg1_imm == 1'b1) begin
        reg1_o <= imm;
    end else if((ex_wreg_i == 1'b1) && (ex_wd_i == reg1_addr_o)) begin
        reg1_o <= ex_wdata_i;   // 采用ex阶段的前传数据
    end else if((mem_wreg_i == 1'b1) && (mem_wd_i == reg1_addr_o)) begin
        reg1_o <= mem_wdata_i;  // 采用mem阶段的前传数据
    end else begin
        reg1_o <= reg1_data_i;  // 采用寄存器读出来的数据
    end
end

// 操作数2输出选择
always_comb begin
    if(rst == `RstEnable) begin
        reg2_o <= `ZeroWord;    // 复位时的值
    end else if(reg2_imm == 1'b1) begin
        reg2_o <= imm;          // 采用立即数
    end else if((ex_wreg_i == 1'b1) && (ex_wd_i == reg2_addr_o)) begin
        reg2_o <= ex_wdata_i;   // 采用ex阶段的前传数据
    end else if((mem_wreg_i == 1'b1) && (mem_wd_i == reg2_addr_o)) begin
        reg2_o <= mem_wdata_i;  // 采用mem阶段的前传数据
    end else begin
        reg2_o <= reg2_data_i;  // 采用寄存器读出来的数据
    end
end

endmodule
