`include "defines.sv"

module pc_reg(
    input wire clk,
    input wire rst,

    input wire branch_flag,
    input wire[`RegBus] branch_addr,

    input wire[5:0] stall,

    output reg[`InstAddrBus] pc,
    output reg ce
);

always_ff @ (posedge clk) begin
    if (ce == `ChipDisable) begin // 初始化时pc设为监控程序首地址
        pc <= 32'h0;              // 监控程序首地址对应物理地址0
    end else if (stall[0] == `NoStop) begin
        if (branch_flag == `Branch) begin
            pc <= branch_addr;
        end else begin
            pc <= pc + 4'h4;          // sram按字编址，所以每次应该是pc+1，这里先按照+4来测试算数指令
        end
    end
end

always_ff @ (posedge clk) begin
    if (rst == `RstEnable) begin
        ce <= `ChipDisable;
    end else begin
        ce <= `ChipEnable;
    end
end

endmodule
