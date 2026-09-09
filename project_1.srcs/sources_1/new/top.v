`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/05/2026 07:19:38 PM
// Design Name: 
// Module Name: top
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module top
  # (
    parameter BUS_SIZE = 8,
    parameter OP_SIZE = 6
  )
  (
    input wire [BUS_SIZE - 1 : 0] switches,
    input wire en_a,
    input wire en_b,
    input wire en_op,
    input wire clock,
    output wire [BUS_SIZE - 1 : 0] leds
  );
  
  wire [BUS_SIZE - 1 : 0] cable_a;
  wire [BUS_SIZE - 1 : 0] cable_b;
  wire [OP_SIZE - 1 : 0] cable_op;
  
  flip_flop #(.BUS_SIZE(BUS_SIZE)) reg_a (
    .clock(clock),
    .enable(en_a),
    .a(switches),
    .b(cable_a)
  );
  
  flip_flop #(.BUS_SIZE(BUS_SIZE)) reg_b (
    .clock(clock),
    .enable(en_b),
    .a(switches),
    .b(cable_b)
  );
  
  flip_flop #(.BUS_SIZE(OP_SIZE)) reg_op (
    .clock(clock),
    .enable(en_op),
    .a(switches[OP_SIZE - 1 : 0]),
    .b(cable_op)
  );
  
  alu #(
    .BUS_SIZE(BUS_SIZE),
    .OP_SIZE(OP_SIZE)
  ) mi_alu (
    .a(cable_a),
    .b(cable_b),
    .op(cable_op),
    .leds(leds)
  );
endmodule
