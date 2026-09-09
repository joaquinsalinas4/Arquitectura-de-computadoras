`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/05/2026 07:19:16 PM
// Design Name: 
// Module Name: flip_flop
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

module flip_flop
  # (
    parameter BUS_SIZE = 8
  )
  (
    input wire clock,
    input wire enable,
    input wire [BUS_SIZE - 1 : 0] a,
    output reg [BUS_SIZE - 1 : 0] b
  );
  
  always @(posedge clock) begin
    if (enable) begin
      b <= a;
    end
  end
endmodule
