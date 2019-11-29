`include "defines.sv"

module openmips(
    input wire           clk,
    input wire           rst,

    input wire[`RegBus]  inst_data_i,
    output wire[`RegBus] inst_addr_o,
    output wire          inst_ce_o,

    output wire[15:0] reg1,

    input wire[`RegBus]  ram_data_i,
    output wire[`RegBus] ram_addr_o,
    output wire[`RegBus] ram_data_o,
    output wire          ram_we_o,
    output wire[3:0]     ram_sel_o,
    output wire[3:0]     ram_ce_o,

    //CP0相关
    input wire[5:0]      int_i,
    output wire          timer_int_o
);

// fake_pc fake_pc0(
//     .clk(clk),
//     .rst(rst),
//     .pc(inst_addr_o),
//     .ce(inst_ce_o)
// );

// assign reg1 = 32'b0;
// assign ram_data_o = 32'b0;
// assign ram_addr_o = 32'b0;
// assign ram_we_o = 1'b0;
// assign ram_ce_o = 1'b0;
// assign ram_sel_o = 1'b0;

wire[`InstAddrBus]  pc;
wire[`InstAddrBus]  id_pc_i;
wire[`InstBus]      id_inst_i;

//连接译码阶段ID模块的输出与ID/EX模块的输入
wire[`AluOpBus]     id_aluop_o;
wire[`AluSelBus]    id_alusel_o;
wire[`RegBus]       id_reg1_o;
wire[`RegBus]       id_reg2_o;
wire                id_wreg_o;
wire[`RegAddrBus]   id_wd_o;

wire                id_is_in_delayslot;
wire[`RegBus]       id_link_addr;
wire                id_next_in_delayslot;

//连接ID/EX模块的输出与执行阶段EX模块的输入
wire[`AluOpBus]     ex_aluop_i;
wire[`AluSelBus]    ex_alusel_i;
wire[`RegBus]       ex_reg1_i;
wire[`RegBus]       ex_reg2_i;
wire                ex_wreg_i;
wire[`RegAddrBus]   ex_wd_i;

wire                ex_is_in_delayslot;
wire[`RegBus]       ex_link_addr;

//连接执行阶段EX模块的输出与EX/MEM模块的输入
wire                ex_wreg_o;
wire[`RegAddrBus]   ex_wd_o;
wire[`RegBus]       ex_wdata_o;
wire                ex_cp0_reg_we_o;
wire[4:0]           ex_cp0_reg_write_addr_o;
wire[`RegBus]       ex_cp0_reg_data_o; 

//连接EX/MEM模块的输出与访存阶段MEM模块的输入
wire                mem_wreg_i;
wire[`RegAddrBus]   mem_wd_i;
wire[`RegBus]       mem_wdata_i;
wire                mem_cp0_reg_we_i;
wire[4:0]           mem_cp0_reg_write_addr_i;
wire[`RegBus]       mem_cp0_reg_data_i;

//连接访存阶段MEM模块的输出与MEM/WB模块的输入
wire                mem_wreg_o;
wire[`RegAddrBus]   mem_wd_o;
wire[`RegBus]       mem_wdata_o;
wire                mem_cp0_reg_we_o;
wire[4:0]           mem_cp0_reg_write_addr_o;
wire[`RegBus]       mem_cp0_reg_data_o;

//连接MEM/WB模块的输出与回写阶段的输入
wire                wb_wreg_i;
wire[`RegAddrBus]   wb_wd_i;
wire[`RegBus]       wb_wdata_i;
wire                wb_cp0_reg_we_i;
wire[4:0]           wb_cp0_reg_write_addr_i;
wire[`RegBus]       wb_cp0_reg_data_i;

//连接译码阶段ID模块与通用寄存器Regfile模块
wire[`RegBus]       reg1_data;
wire[`RegBus]       reg2_data;
wire[`RegAddrBus]   reg1_addr;
wire[`RegAddrBus]   reg2_addr;

wire[5:0] stall;
wire stall_req_id;
wire stall_req_ex;

wire is_in_delayslot; // 从id/ex回传到id的信号
wire[`InstAddrBus] branch_addr;
wire branch_flag;

wire[`InstBus] id_inst_o;
wire[`InstBus] ex_inst_i;
wire[`AluOpBus]  ex_aluop_o;
wire[`RegBus]    ex_mem_addr_o;
wire[`RegBus]    ex_reg2_o;

wire[`AluOpBus]   mem_aluop_o;
wire[`RegBus]     mem_mem_addr_o;
wire[`RegBus]     mem_reg2_o;

//直接连接EX模块与CP0的两根线，mfc0指令
wire[`RegBus]   cp0_data_o;
wire[4:0]       cp0_raddr_i;

wire mem_ce;
assign ram_ce_o = mem_ce;

//异常相关
//从CTRL模块引出的线
wire            flush;
wire[`RegBus]   new_pc;
//从ID模块引出的线
wire[31:0]      id_excepttype_o;
wire[`RegBus]   id_current_inst_address_o;
//接入EX模块的线
wire[31:0]      ex_excepttype_i;	
wire[`RegBus]   ex_current_inst_address_i;
//从EX模块引出的线
wire[31:0]      ex_excepttype_o;
wire[`RegBus]   ex_current_inst_address_o;
wire            ex_is_in_delayslot_o;
//接入MEM模块的线
wire[31:0]      mem_excepttype_i;	
wire[`RegBus]   mem_current_inst_address_i;
wire            mem_is_in_delayslot_i;
//从MEM模块引出的线
wire[31:0]      mem_excepttype_o;
wire[`RegBus]   mem_current_inst_address_o;
wire            mem_is_in_delayslot_o;
wire[`RegBus]   latest_epc;
//从CP0引出的线
wire[`RegBus]   cp0_count;
wire[`RegBus]	cp0_compare;
wire[`RegBus]	cp0_status;
wire[`RegBus]	cp0_cause;
wire[`RegBus]	cp0_epc;
wire[`RegBus]	cp0_config;
wire[`RegBus]	cp0_prid;

//pc_reg例化
pc_reg pc_reg0(
    .clk(clk),
    .rst(rst),
    .stall(stall),
    .pc(pc),
    .ce(inst_ce_o),
    .branch_addr(branch_addr),
    .branch_flag(branch_flag),
    //异常相关
    .flush(flush),
    .new_pc(new_pc)
);

assign inst_addr_o = pc;

//IF/ID模块例化
if_id if_id0(
    .clk(clk),
    .rst(rst),
    .if_pc(pc),
    .if_inst(inst_data_i),
    .stall(stall),
    .id_pc(id_pc_i),
    .id_inst(id_inst_i),
    //异常相关
    .flush(flush)
);

//译码阶段ID模块
id id0(
    .rst(rst),
    .pc_i(id_pc_i),
    .inst_i(id_inst_i),

    .reg1_data_i(reg1_data),
    .reg2_data_i(reg2_data),

    // ex阶段的前传数据
    .ex_wreg_i(ex_wreg_o),
    .ex_wdata_i(ex_wdata_o),
    .ex_wd_i(ex_wd_o),

    // mem阶段的前传数据
    .mem_wreg_i(mem_wreg_o),
    .mem_wdata_i(mem_wdata_o),
    .mem_wd_i(mem_wd_o),

    // 寄存器读取地址
    .reg1_addr_o(reg1_addr),
    .reg2_addr_o(reg2_addr),

    //送到ID/EX模块的信息
    .aluop_o(id_aluop_o),
    .alusel_o(id_alusel_o),
    .reg1_o(id_reg1_o),
    .reg2_o(id_reg2_o),
    .wd_o(id_wd_o),
    .wreg_o(id_wreg_o),

    .stallreq(stall_req_id),

    .is_in_delayslot_i(is_in_delayslot),
    .is_in_delayslot_o(id_is_in_delayslot),
    .link_addr(id_link_addr),
    .next_in_delayslot(id_next_in_delayslot),
    .branch_addr(branch_addr),
    .branch_flag(branch_flag),

    .inst_o(id_inst_o),

    .ex_aluop(ex_aluop_o),

    //异常相关
    .excepttype_o(id_excepttype_o),
    .current_inst_address_o(id_current_inst_address_o)
);

//通用寄存器Regfile例化
regfile regfile1(
    .clk (clk),
    .rst (rst),

    .reg1(reg1),

    .we    (wb_wreg_i),
    .waddr (wb_wd_i),
    .wdata (wb_wdata_i),
    .raddr1 (reg1_addr),
    .rdata1 (reg1_data),
    .raddr2 (reg2_addr),
    .rdata2 (reg2_data)
);

//ID/EX模块
id_ex id_ex0(
    .clk(clk),
    .rst(rst),

    .stall(stall),

    //从译码阶段ID模块传递的信息
    .id_aluop(id_aluop_o),
    .id_alusel(id_alusel_o),
    .id_reg1(id_reg1_o),
    .id_reg2(id_reg2_o),
    .id_wd(id_wd_o),
    .id_wreg(id_wreg_o),

    //传递到执行阶段EX模块的信息
    .ex_aluop(ex_aluop_i),
    .ex_alusel(ex_alusel_i),
    .ex_reg1(ex_reg1_i),
    .ex_reg2(ex_reg2_i),
    .ex_wd(ex_wd_i),
    .ex_wreg(ex_wreg_i),

    .id_is_in_delayslot(id_is_in_delayslot),
    .id_link_addr(id_link_addr),
    .next_in_delayslot(id_next_in_delayslot),
    .ex_is_in_delayslot(ex_is_in_delayslot),
    .ex_link_addr(ex_link_addr),
    .is_in_delayslot_o(is_in_delayslot),

    .id_inst(id_inst_o),
    .ex_inst(ex_inst_i),

    //异常相关
    .flush(flush),
    .id_current_inst_address(id_current_inst_address_o),
    .id_excepttype(id_excepttype_o),
    .ex_current_inst_address(ex_current_inst_address_i),
    .ex_excepttype(ex_excepttype_i)
);

//EX模块
ex ex0(
    .rst(rst),

    //送到执行阶段EX模块的信息
    .aluop_i(ex_aluop_i),
    .alusel_i(ex_alusel_i),
    .reg1_i(ex_reg1_i),
    .reg2_i(ex_reg2_i),
    .wd_i(ex_wd_i),
    .wreg_i(ex_wreg_i),

    //EX模块的输出到EX/MEM模块信息
    .wd_o(ex_wd_o),
    .wreg_o(ex_wreg_o),
    .wdata_o(ex_wdata_o),

    .link_addr(ex_link_addr),
    .is_in_delayslot(ex_is_in_delayslot),

    .inst_i(ex_inst_i),
    .aluop_o(ex_aluop_o),
    .mem_addr_o(ex_mem_addr_o),
    .reg2_o(ex_reg2_o),

    .last_aluop(mem_aluop_o),
    .last_mem_addr(mem_mem_addr_o),
    .stallreq(stall_req_ex),

    //访存阶段的指令是否要写CP0
    .mem_cp0_reg_we(mem_cp0_reg_we_o),
    .mem_cp0_reg_write_addr(mem_cp0_reg_write_addr_o),
    .mem_cp0_reg_data(mem_cp0_reg_data_o),
    //回写阶段的指令是否要写CP0
    .wb_cp0_reg_we(wb_cp0_reg_we_i),
    .wb_cp0_reg_write_addr(wb_cp0_reg_write_addr_i),
    .wb_cp0_reg_data(wb_cp0_reg_data_i),
    //读CP0中寄存器，直接与CP0相连
    .cp0_reg_data_i(cp0_data_o),
	.cp0_reg_read_addr_o(cp0_raddr_i),
    //向EX/MEM模块传递，用于写CP0中的寄存器
    .cp0_reg_we_o(ex_cp0_reg_we_o),
	.cp0_reg_write_addr_o(ex_cp0_reg_write_addr_o),
	.cp0_reg_data_o(ex_cp0_reg_data_o),

    //异常相关
    .excepttype_i(ex_excepttype_i),
    .current_inst_address_i(ex_current_inst_address_i),
    .excepttype_o(ex_excepttype_o),
    .is_in_delayslot_o(ex_is_in_delayslot_o),
    .current_inst_address_o(ex_current_inst_address_o)
);

//EX/MEM模块
ex_mem ex_mem0(
    .clk(clk),
    .rst(rst),

    .stall(stall),

    //来自执行阶段EX模块的信息
    .ex_wd(ex_wd_o),
    .ex_wreg(ex_wreg_o),
    .ex_wdata(ex_wdata_o),

    //送到访存阶段MEM模块的信息
    .mem_wd(mem_wd_i),
    .mem_wreg(mem_wreg_i),
    .mem_wdata(mem_wdata_i),
    .ex_aluop(ex_aluop_o),
    .ex_mem_addr(ex_mem_addr_o),
    .ex_reg2(ex_reg2_o),
    .mem_aluop(mem_aluop_o),
    .mem_mem_addr(mem_mem_addr_o),
    .mem_reg2(mem_reg2_o),

    //CP0相关信号
    .ex_cp0_reg_we(ex_cp0_reg_we_o),
	.ex_cp0_reg_write_addr(ex_cp0_reg_write_addr_o),
	.ex_cp0_reg_data(ex_cp0_reg_data_o),
    .mem_cp0_reg_we(mem_cp0_reg_we_i),
	.mem_cp0_reg_write_addr(mem_cp0_reg_write_addr_i),
	.mem_cp0_reg_data(mem_cp0_reg_data_i),

    //异常相关
    .flush(flush),
    .ex_excepttype(ex_excepttype_o),
    .ex_is_in_delayslot(ex_is_in_delayslot_o),
    .ex_current_inst_address(ex_current_inst_address_o),
    .mem_excepttype(mem_excepttype_i),
    .mem_is_in_delayslot(mem_is_in_delayslot_i),
    .mem_current_inst_address(mem_current_inst_address_i)
);

//MEM模块例化
mem mem0(
    .rst(rst),

    //来自EX/MEM模块的信息
    .wd_i(mem_wd_i),
    .wreg_i(mem_wreg_i),
    .wdata_i(mem_wdata_i),

    //送到MEM/WB模块的信息
    .wd_o(mem_wd_o),
    .wreg_o(mem_wreg_o),
    .wdata_o(mem_wdata_o),

    // l/s相关的信号
    .aluop_i(mem_aluop_o),
    .mem_addr_i(mem_mem_addr_o),
    .reg2_i(mem_reg2_o),
    .mem_data_i(ram_data_i),
    .mem_addr_o(ram_addr_o),
    .mem_we_o(ram_we_o),
    .mem_sel_o(ram_sel_o),
    .mem_data_o(ram_data_o),
    .mem_ce_o(mem_ce),

    //cp0相关信号
    .cp0_reg_we_i(mem_cp0_reg_we_i),
	.cp0_reg_write_addr_i(mem_cp0_reg_write_addr_i),
	.cp0_reg_data_i(mem_cp0_reg_data_i),
    .cp0_reg_we_o(mem_cp0_reg_we_o),
	.cp0_reg_write_addr_o(mem_cp0_reg_write_addr_o),
	.cp0_reg_data_o(mem_cp0_reg_data_o),

    //异常相关
    //输入
    .excepttype_i(mem_excepttype_i),
	.is_in_delayslot_i(mem_is_in_delayslot_i),
	.current_inst_address_i(mem_current_inst_address_i),
    .cp0_status_i(cp0_status),
	.cp0_cause_i(cp0_cause),
	.cp0_epc_i(cp0_epc),
    .wb_cp0_reg_we(wb_cp0_reg_we_i),
	.wb_cp0_reg_write_addr(wb_cp0_reg_write_addr_i),
	.wb_cp0_reg_data(wb_cp0_reg_data_i),
    //输出
    .excepttype_o(mem_excepttype_o),
	.is_in_delayslot_o(mem_is_in_delayslot_o),
	.current_inst_address_o(mem_current_inst_address_o),
    .cp0_epc_o(latest_epc)
);

//MEM/WB模块
mem_wb mem_wb0(
    .clk(clk),
    .rst(rst),

    .stall(stall),

    //来自访存阶段MEM模块的信息
    .mem_wd(mem_wd_o),
    .mem_wreg(mem_wreg_o),
    .mem_wdata(mem_wdata_o),

    //送到回写阶段的信息
    .wb_wd(wb_wd_i),
    .wb_wreg(wb_wreg_i),
    .wb_wdata(wb_wdata_i),

    //CP0相关信号
    .mem_cp0_reg_we(mem_cp0_reg_we_o),
	.mem_cp0_reg_write_addr(mem_cp0_reg_write_addr_o),
	.mem_cp0_reg_data(mem_cp0_reg_data_o),
    .wb_cp0_reg_we(wb_cp0_reg_we_i),
	.wb_cp0_reg_write_addr(wb_cp0_reg_write_addr_i),
	.wb_cp0_reg_data(wb_cp0_reg_data_i),

    //异常相关
    .flush(flush)
);

ctrl ctrl0(
    .rst(rst),
    .stall_req_id(stall_req_id),
    .stall_req_ex(stall_req_ex),
    .stall(stall),
    .mem_ce(mem_ce),

    //异常相关
    .excepttype_i(mem_excepttype_o),
	.cp0_epc_i(latest_epc),
    .new_pc(new_pc),
	.flush(flush)
);

cp0_reg cp0_reg0(
    .clk(clk),
    .rst(rst),
    
    .raddr_i(cp0_raddr_i),
    .we_i(wb_cp0_reg_we_i),
    .waddr_i(wb_cp0_reg_write_addr_i),
    .data_i(wb_cp0_reg_data_i),
    
    .int_i(int_i),
    
    .timer_int_o(timer_int_o),

    //异常相关
    //输入
    .excepttype_i(mem_excepttype_o),
    .current_inst_addr_i(mem_current_inst_address_o),
    .is_in_delayslot_i(mem_is_in_delayslot_o),
    //输出
    .data_o(cp0_data_o),
	.count_o(cp0_count),
	.compare_o(cp0_compare),
	.status_o(cp0_status),
	.cause_o(cp0_cause),
	.epc_o(cp0_epc),
	.config_o(cp0_config),
	.prid_o(cp0_prid)
);

endmodule
