`include "defines.sv"

module ctrl(

    input wire  rst,
    input wire  stall_req_id,
    input wire  mem_ce,
    input wire  stall_req_ex,

    output reg[5:0]  stall,

    //异常相关，输入来自MEM
    input wire[`RegBus] cp0_epc_i,
    input wire[31:0]    excepttype_i,
    output reg[`RegBus] new_pc,
    output reg          flush
);

always_comb begin
    if(rst == `RstEnable) begin
        stall <= 6'b000000;
        flush <= 1'b0;
        new_pc  <= `ZeroWord;
    end else if(excepttype_i != `ZeroWord) begin
        flush   <= 1'b1;
        stall   <= 6'b000000;
        case(excepttype_i)
            32'h00000001:   begin   // Interrupt
                new_pc  <= 32'h80001180;
            end
            32'h00000008:   begin   // Syscall
                new_pc  <= 32'h80001180;
            end
            32'h0000000a:   begin   // Inst invalid
                new_pc  <= 32'h80001180;
            end
            32'h0000000d:   begin   // Trap
                new_pc  <= 32'h80001180;
            end
            32'h0000000c:   begin   // ov
                new_pc  <= 32'h80001180;
            end
            32'h0000000e:   begin   // eret
                new_pc  <= cp0_epc_i;
            end
            default:    begin
            end
        endcase
    end else if(stall_req_id == `Stop) begin
        stall <= 6'b000111;
        flush <= 1'b0;
    end else if(stall_req_ex == `Stop) begin
        stall <= 6'b001111;
        flush <= 1'b0;
    end else if(mem_ce == 1'b1) begin
        stall <= 6'b000001;
        flush <= 1'b0;
    end else begin
        stall <= 6'b000000;
        flush <= 1'b0;
        new_pc  <= `ZeroWord;
    end    //if
end      //always

endmodule