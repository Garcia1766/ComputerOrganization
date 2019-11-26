`include "defines.sv"

module if_id(
    input wire clk,
    input wire rst,
    input wire[`InstAddrBus] if_pc,
    input wire[`InstBus]     if_inst,
    input wire[5:0]          stall,

    output reg[`InstAddrBus] id_pc,
    output reg[`InstBus]     id_inst
);

always_ff @ (posedge clk) begin
    if (rst == `RstEnable || (stall[1] == `Stop && stall[2] == `NoStop)) begin
        id_pc <= `ZeroWord;
        id_inst <= `ZeroWord;
    end else if (stall[1] == `NoStop) begin      // 小端序转换成大端序
        id_pc <= if_pc;
        id_inst <= {if_inst[7:0], if_inst[15:8], if_inst[23:16], if_inst[31:24]};
    end
end

endmodule
