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

endmodule