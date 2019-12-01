`include "defines.sv"

module ctrl(

    input wire  rst,
    input wire  stall_req_id,
    input wire  mem_ce,
    input wire  stall_req_ex,
    input wire  stallreq_store,

    output reg[5:0]  stall

);

always_comb begin
    if(rst == `RstEnable) begin
        stall <= 6'b000000;
    end else if(stallreq_store == 1'b1) begin
        stall <= 6'b011111;
    end else if(stall_req_id == `Stop) begin
        stall <= 6'b000111;
    end else if(stall_req_ex == `Stop) begin
        stall <= 6'b001111;
    end else if(mem_ce == 1'b1) begin
        stall <= 6'b000001;
    end else begin
        stall <= 6'b000000;
    end    //if
end      //always

endmodule