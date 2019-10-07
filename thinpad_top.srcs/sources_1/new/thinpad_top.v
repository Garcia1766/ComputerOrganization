module thinpad_top(
    input wire clk,
    input wire rst,
    input wire[15:0] data,
    output wire[15:0] r
);

wire[15:0] a;
wire[15:0] b;
wire[3:0] op;

state_machine st_m(.clk(clk), .rst(rst), .data(data), .op(op), .a(a), .b(b));
alu alu_1(.op(op), .a(a), .b(b), .r(r));

endmodule
