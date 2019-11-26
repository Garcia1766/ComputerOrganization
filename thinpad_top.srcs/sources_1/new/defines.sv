//全局
`define RstEnable           1'b1
`define RstDisable          1'b0
`define ZeroWord            32'h00000000
`define WriteEnable         1'b1
`define WriteDisable        1'b0
`define ReadEnable          1'b1
`define ReadDisable         1'b0
`define AluOpBus            4:0
`define AluSelBus           2:0
`define InstValid           1'b0
`define InstInvalid         1'b1
`define Stop                1'b1
`define NoStop              1'b0
`define InDelaySlot         1'b1
`define NotInDelaySlot      1'b0
`define Branch              1'b1
`define NotBranch           1'b0
`define InterruptAssert     1'b1
`define InterruptNotAssert  1'b0
`define TrapAssert          1'b1
`define TrapNotAssert       1'b0
`define True_v              1'b1
`define False_v             1'b0
`define ChipEnable          1'b1
`define ChipDisable         1'b0

//指令

// [5:0]
`define EXE_NOP  6'b000000

`define EXE_AND  6'b100100
`define EXE_OR   6'b100101
`define EXE_XOR  6'b100110
`define EXE_SLL  6'b000000
`define EXE_SRL  6'b000010

`define EXE_CLZ  6'b100000
`define EXE_MOVN 6'b001011
`define EXE_ADDU 6'b100001
`define EXE_SLT  6'b101010
`define EXE_SLTU 6'b101011
`define EXE_JR   6'b001000


// [31:26]
`define EXE_ANDI  6'b001100
`define EXE_ORI   6'b001101
`define EXE_XORI  6'b001110
`define EXE_LUI   6'b001111
`define EXE_ADDIU 6'b001001
`define EXE_SLTI  6'b001010
`define EXE_SLTIU 6'b001011
`define EXE_J     6'b000010
`define EXE_JAL   6'b000011
`define EXE_BEQ   6'b000100
`define EXE_BGTZ  6'b000111
`define EXE_BNE   6'b000101


`define EXE_SPECIAL  6'b000000
`define EXE_SPECIAL2 6'b011100

//AluOp
`define EXE_NOP_OP   5'b00000

`define EXE_AND_OP   5'b00001
`define EXE_OR_OP    5'b00010
`define EXE_XOR_OP   5'b00011
`define EXE_SLL_OP   5'b00100
`define EXE_SRL_OP   5'b00101
`define EXE_CLZ_OP   5'b00110
`define EXE_MOVN_OP  5'b00111
`define EXE_ADD_OP   5'b01000
`define EXE_SLT_OP   5'b01001
`define EXE_SLTU_OP  5'b01010

`define EXE_JR_OP    5'b00001
`define EXE_J_OP     5'b00010
`define EXE_JAL_OP   5'b00011
`define EXE_BEQ_OP   5'b00100
`define EXE_BGTZ_OP  5'b00101
`define EXE_BNE_OP   5'b00110

//AluSel
`define EXE_RES_ARITH 3'b001
`define EXE_RES_MOVE  3'b010
`define EXE_RES_JB    3'b011
`define EXE_RES_NOP   3'b000

//指令存储器sram
`define InstAddrBus     31:0
`define InstBus         31:0

//通用寄存器regfile
`define RegAddrBus      4:0
`define RegBus          31:0
`define RegWidth        32
`define DoubleRegWidth  64
`define DoubleRegBus    63:0
`define RegNum          32
`define RegNumLog2      5
`define NOPRegAddr      5'b00000
