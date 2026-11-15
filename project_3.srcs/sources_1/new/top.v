`timescale 1ns / 1ps
`default_nettype none

module top
#(
    parameter BUS_SIZE     = 32,
    parameter ADDRESS_SIZE = 8,
    parameter BYTE_SIZE    = 8,
    parameter ticks = 16,
    parameter bits = 8,
    parameter ciclos = 325,
    parameter N = 9
  )
  (
    input wire clock,
    input wire rx,
    input wire reset,
    output wire tx
  );

  wire tick, rx_done, tx_start, tx_done, cpu_enable, wr_en;
  wire [ADDRESS_SIZE-1:0] tx_data, rx_data, wr_addr;
  wire [BUS_SIZE-1:0] pc, next_pc, wr_data, instr, pc_latch, inst_latch;

  assign next_pc = pc + 1;

  baud_rate
  #(
    .ciclos(ciclos),
    .N(N)
  )
  baud_rate_1
  (
    .clock(clock),
    .tick(tick),
    .reset(reset)
  );

  rx_uart
  #(
    .ticks(ticks),
    .bits(bits)
  )
  rx_uart_1
  (
    .clock(clock),
    .reset(reset),
    .rx(rx),
    .sample_tick(tick),
    .rx_done(rx_done),
    .dout(rx_data)
  );

  tx_uart
  #(
    .BUS_SIZE(bits)
  )
  tx_uart_1
  (
    .clock(clock),
    .reset(reset),
    .sample_tick(tick),
    .tx_start(tx_start),
    .d_in(tx_data),
    .tx(tx),
    .tx_done(tx_done)
  );

  pc
  #(
    .BUS_SIZE(BUS_SIZE)
  )
  pc_1
  (
    .clock(clock),
    .reset(reset),
    .enable(cpu_enable),
    .next_pc(next_pc),
    .pc(pc)
  );

  mem_programa
  #(
    .BUS_SIZE(BUS_SIZE),
    .ADDR_SIZE(ADDRESS_SIZE)
  )
  mem_programa_1
  (
    .clock(clock),
    .addr(pc[ADDRESS_SIZE-1:0]),
    .instr(instr),
    .wr_en(wr_en),
    .wr_addr(wr_addr),
    .wr_data(wr_data)
  );

  latch_if_id
  #(
    .BUS_SIZE(BUS_SIZE)
  )
  latch_if_id_1
  (
    .clock(clock),
    .reset(reset),
    .enable(cpu_enable),
    .dr(instr),
    .pc_in(pc),
    .pc4_in(next_pc),
    .pc4_out(),
    .pc_out(pc_latch),
    .inst_out(inst_latch)
  );

  debug_unit
  #(
    .BUS_SIZE(BUS_SIZE),
    .ADDRESS_SIZE(ADDRESS_SIZE),
    .BYTE_SIZE(BYTE_SIZE)
  )
  debug_unit_1
  (
    .clock(clock),
    .reset(reset),
    .rx_done(rx_done),
    .rx_data(rx_data),
    .tx_start(tx_start),
    .tx_data(tx_data),
    .tx_done(tx_done),
    .mem_wr_en(wr_en),
    .mem_wr_addr(wr_addr),
    .mem_wr_data(wr_data),
    .cpu_enable(cpu_enable),
    .pc(pc_latch),
    .if_id_instr(inst_latch)
  );

  // Etapa ID
  wire flush;
  wire [4:0] rs1    = inst_latch[19:15];
  wire [4:0] rs2    = inst_latch[24:20];
  wire [4:0] rd     = inst_latch[11:7];
  wire [2:0] funct3 = inst_latch[14:12];
  wire [6:0] funct7 = inst_latch[31:25];

  reg_bank
  (
    .BUS_SIZE(BUS_SIZE),
    .ADDR_SIZE(ADDR_SIZE)
  )
  reg_bank_1
  (
    .clock(clock), 
    .reset(reset),
    .enable(cpu_enable),
    .rs1_addr(rs1),
    .rs2_addr(rs2),
    .rs1_data(),
    .rs2_data(),
    .reg_write(),
    .rd_addr(rd),
    .wr_data(),
    .dbg_addr(),
    .dbg_data()
  );

  latch_id_ex
  (
    .clock(clock),
    .reset(reset),
    .enable(cpu_enable),
    .flush(flush),
    .pc_in(),
    .pc4_in(),
    .rs1_data_in(),
    .rs2_data_in(),
    .imm_in(),
    .rs1_in(rs1),
    .rs2_in(rs2),
    .rd_in(rd),
    .funct3_in(funct3),
    .funct7_in(funct7),
    .inst_in(),
    .alu_src_in(),
    .alu_op_in(),
    .branch_in(),
    .jump_in(),
    .mem_read_in(),
    .mem_write_in(),
    .reg_write_in(),
    .mem_to_reg_in(),
    .pc_out(),
    .pc4_out(),
    .rs1_data_out(),
    .rs2_data_out(),
    .imm_out(),
    .rs1_out(),
    .rs2_out(),
    .rd_out(),
    .funct3_out(),
    .funct7_out(),
    .inst_out(),
    .alu_src_out(),
    .alu_op_out(),
    .branch_out(),
    .jump_out(),
    .mem_read_out(),
    .mem_write_out(),
    .reg_write_out(),
    .mem_to_reg_out()
  )
  latch_id_ex_1
  (
    .BUS_SIZE(BUS_SIZE),
    .REG_SIZE(5),
    .ALU_OP_SIZE(4)
  );

endmodule
