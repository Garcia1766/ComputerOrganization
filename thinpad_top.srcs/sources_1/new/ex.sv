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
    output reg[`RegBus]     wdata_o

);

reg[`RegBus] logicout;

always @ (*) begin
    if(rst == `RstEnable) begin
        logicout <= `ZeroWord;
    end else begin
        case (aluop_i)
            `EXE_OR_OP: begin logicout <= reg1_i | reg2_i; end
            default:    begin logicout <= `ZeroWord; end
        endcase
    end    //if
end      //always


always @ (*) begin
    wd_o <= wd_i;
    wreg_o <= wreg_i;
    case (alusel_i)
        `EXE_RES_LOGIC: begin
            wdata_o <= logicout;
        end
        default: begin
            wdata_o <= `ZeroWord;
        end
    endcase
end

endmodule