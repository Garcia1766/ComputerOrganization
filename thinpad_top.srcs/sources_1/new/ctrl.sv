`include "defines.sv"

module ctrl(

    input wire  rst,
    input wire  stall_req_id,

    output reg[5:0]  stall

);

always_comb begin
    if(rst == `RstEnable) begin
        stall <= 6'b000000;
    end else if(stall_req_id == `Stop) begin
        stall <= 6'b000111;
    end else begin
        stall <= 6'b000000;
    end    //if
end      //always

endmodule