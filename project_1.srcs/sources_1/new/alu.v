`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/05/2026 07:14:07 PM
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
    parameter BUS_SIZE = 8,
    parameter OP_SIZE = 6
  )
  (
    input wire [BUS_SIZE - 1 : 0] a,
    input wire [BUS_SIZE - 1 : 0] b,
    input wire [OP_SIZE - 1 : 0] op,
    output wire [BUS_SIZE - 1 : 0] leds
  );
  
  reg [BUS_SIZE - 1 : 0] resultado;
  
  always @(*) begin
    case(op)
      6'b100000: resultado = a + b;
      6'b100010: resultado = a - b;
      6'b100100: resultado = a & b;
      6'b100101: resultado = a | b;
      6'b100110: resultado = a ^ b;
      6'b000011: resultado = $signed(a) >>> b;
      6'b000010: resultado = a >> b;
      6'b100111: resultado =  ~(a | b);
      default: resultado = 0;
    endcase
  end
    
  assign leds = resultado;
endmodule
