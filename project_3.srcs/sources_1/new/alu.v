`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/26/2026 12:40:44 AM
// Design Name: 
// Module Name: alu
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


module alu
  # (
    parameter BUS_SIZE = 32,
    parameter OP_SIZE  = 4
  )
  (
    input  wire [BUS_SIZE - 1 : 0] a,
    input  wire [BUS_SIZE - 1 : 0] b,
    input  wire [OP_SIZE - 1 : 0]  op,
    output reg  [BUS_SIZE - 1 : 0] result,
    output wire                    zero
  );

  localparam ADD    = 4'b0000;
  localparam SUB    = 4'b0001;
  localparam AND    = 4'b0010;
  localparam OR     = 4'b0011;
  localparam XOR    = 4'b0100;
  localparam SRA    = 4'b0101;
  localparam SRL    = 4'b0110;
  localparam SLL    = 4'b0111;
  localparam SLT    = 4'b1000;
  localparam SLTU   = 4'b1001;
  localparam COPY_B = 4'b1010;

  always @(*) begin
    case (op)
      ADD:    result = a + b;
      SUB:    result = a - b;
      AND:    result = a & b;
      OR:     result = a | b;
      XOR:    result = a ^ b;
      SRA:    result = $signed(a) >>> b[4:0];
      SRL:    result = a >> b[4:0];
      SLL:    result = a << b[4:0];
      SLT:    result = ($signed(a) < $signed(b)) ? 1 : 0;
      SLTU:   result = (a < b) ? 1 : 0;
      COPY_B: result = b;
      default: result = 0;
    endcase
  end

  assign zero = (result == 0);

endmodule