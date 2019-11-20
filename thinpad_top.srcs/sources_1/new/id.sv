`include "defines.sv"

module id(
    input wire                rst,
    input wire[`InstAddrBus]  pc_i,         // pc地址
    input wire[`InstBus]      inst_i,       // 指令
    input wire[`RegBus]       reg1_data_i,  // 寄存器1的读取数据
    input wire[`RegBus]       reg2_data_i,  // 寄存器2的读取数据

    // regfile需要的信号
    output reg                reg1_read_o,  // reg1读使能
    output reg                reg2_read_o,  // reg2读使能
    output reg[`RegAddrBus]   reg1_addr_o,  // reg1读地址
    output reg[`RegAddrBus]   reg2_addr_o,  // reg2读地址

    // ex阶段需要的信号
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
reg[`RegBus] imm;
reg instvalid;

// 译码的组合逻辑
always @ (*) begin
    if (rst == `RstEnable) begin
        aluop_o     <= `EXE_NOP_OP;
        alusel_o    <= `EXE_RES_NOP;
        wd_o        <= `NOPRegAddr;
        wreg_o      <= `WriteDisable;
        instvalid   <= `InstValid;
        reg1_read_o <= 1'b0;
        reg2_read_o <= 1'b0;
        reg1_addr_o <= `NOPRegAddr;
        reg2_addr_o <= `NOPRegAddr;
        imm         <= `ZeroWord;
    end else begin
        aluop_o     <= `EXE_NOP_OP;
        alusel_o    <= `EXE_RES_NOP;
        wd_o        <= inst_i[15:11];
        wreg_o      <= `WriteDisable;
        instvalid   <= `InstInvalid;
        reg1_read_o <= 1'b0;
        reg2_read_o <= 1'b0;
        reg1_addr_o <= inst_i[25:21];
        reg2_addr_o <= inst_i[20:16];
        imm         <= `ZeroWord;

        case (op)
        `EXE_ORI: begin
            wreg_o      <= `WriteEnable;          // 需要写回寄存器
            aluop_o     <= `EXE_OR_OP;            // 子类型是or运算
            alusel_o    <= `EXE_RES_LOGIC;        // 类型是逻辑运算
            reg1_read_o <= 1'b1;                  // 需要读操作数1
            reg2_read_o <= 1'b0;                  // 不需要读操作数2
            imm         <= {16'h0, inst_i[15:0]}; // 立即数
            wd_o        <= inst_i[20:16];         // 目标寄存器地址
            instvalid   <= `InstValid;
        end
        default: begin
        end
        endcase    //case op
    end    //if
end    //always

// 操作数1输出选择
always @ (*) begin
    if(rst == `RstEnable) begin
        reg1_o <= `ZeroWord;
    end else if(reg1_read_o == 1'b1) begin
        reg1_o <= reg1_data_i;
    end else if(reg1_read_o == 1'b0) begin
        reg1_o <= imm;
    end else begin
        reg1_o <= `ZeroWord;
    end
end

// 操作数2输出选择
always @ (*) begin
    if(rst == `RstEnable) begin
        reg2_o <= `ZeroWord;
    end else if(reg2_read_o == 1'b1) begin
        reg2_o <= reg2_data_i;
    end else if(reg2_read_o == 1'b0) begin
        reg2_o <= imm;
    end else begin
        reg2_o <= `ZeroWord;
    end
end

endmodule
