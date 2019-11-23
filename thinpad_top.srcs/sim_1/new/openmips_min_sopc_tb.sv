`include "defines.sv"
`timescale 1ns/1ps

module openmips_min_sopc_tb();

reg     CLOCK_50;
reg     rst;
wire[`InstAddrBus] inst_addr;
reg[`InstBus] inst;
wire rom_ce;

initial begin
    CLOCK_50 = 1'b0;
    forever #10 CLOCK_50 = ~CLOCK_50;
end

initial begin
    #5 rst = `RstEnable;
    inst = 32'b0;
    #100 rst = `RstDisable;   // 以下皆为小端序指令

    //     inst = 32'h00110134;  // ori $1, $0, 0x1100
    // #20 inst = 32'h20000234;  // ori $2, $0, 0x0020
    // #20 inst = 32'h00ff0334;  // ori $3, $0, 0xff00
    // #20 inst = 32'hffff0434;  // ori $4, $0, 0xffff

    // #20 inst = 32'h00110134;  // ori $1, $0, 0x1100
    // #20 inst = 32'h20002134;  // ori $1, $1, 0x0020
    // #20 inst = 32'h00442134;  // ori $1, $1, 0x4400
    // #20 inst = 32'h44002134;  // ori $1, $1, 0x0044

    // #20 inst = 32'h00110134;  // ori $1, $0, 0x1100
    // #20 inst = 32'h20002134;  // ori $1, $1, 0x0020
    // #20 inst = 32'hf00f2130;  // andi $1, $1, 0x0ff0
    // #20 inst = 32'h44002130;  // andi $1, $1, 0x0044

    #20 inst = 32'h0101013c;  // lui  $1, 0x0101
    #20 inst = 32'h01012134;  // ori  $1, $1, 0x0101
    #20 inst = 32'h00112234;  // ori  $2, $1, 0x1100        # $2 = $1 | 0x1100 = 0x01011101
    #20 inst = 32'h25082200;  // or   $1, $1, $2            # $1 = $1 | $2 = 0x01011101
    #20 inst = 32'hfe002330;  // andi $3, $1, 0x00fe        # $3 = $1 & 0x00fe = 0x00000000
    #20 inst = 32'h24086100;  // and  $1, $3, $1            # $1 = $3 & $1 = 0x00000000
    #20 inst = 32'h00ff2438;  // xori $4, $1, 0xff00        # $4 = $1 ^ 0xff00 = 0x0000ff00
    #20 inst = 32'h26088100;  // xor  $1, $4, $1            # $1 = $4 ^ $1 = 0x0000ff00
    #20 inst = 32'hc0080100;  // sll  $1, $1, 0x3           # $1 = 0x0007f800
    #20 inst = 32'h02090100;  // srl  $1, $1, 0x4           # $1 = 0x00007f80
    #20 inst = 32'h20102270;  // clz  $2, $1                # $2 = 0x00000011
    #20 inst = 32'h0b182100;  // movn $3, $1, $1            # $3 = 0x00007f80
    #20 inst = 32'h21186200;  // addu $3, $3, $2            # $3 = 0x00007f91
    #20 inst = 32'h34126324;  // addiu $3,$3, 0x1234        # $3 = 0x000091c5

    // #20 inst = 32'hffff0134;     // ori $1, $0, 0xffff
    // #20 inst = 32'h000c0100;     // sll $1, $1, 16             # $1 = 0xffff0000
    // #20 inst = 32'h2a102000;     // slt $2, $1, $0             # $2 = 1
    // #20 inst = 32'h2b102000;     // sltu $2, $1, $0            # $2 = 0
    // #20 inst = 32'h00802228;     // slti $2, $1, 0x8000        # $2 = 1
    // #20 inst = 32'h0080222c;     // sltiu $2, $1, 0x8000       # $2 = 1
    #1000 $stop;
end

openmips openmips0(
    .clk(CLOCK_50),
    .rst(rst),

    .rom_addr_o(inst_addr),
    .rom_data_i(inst),
    .rom_ce_o(rom_ce)
);

endmodule