`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/26/2026 02:44:13 PM
// Design Name: 
// Module Name: mem_programa
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


module mem_programa
  #(
    parameter BUS_SIZE  = 32,
    parameter ADDR_SIZE = 8
  )
  (
    input wire clk,

    // Lectura (procesador, etapa IF)
    input wire [ADDR_SIZE-1:0] addr,
    output wire [BUS_SIZE-1:0]  instr,

    // Escritura (Debug Unit)
    input wire wr_en,
    input wire [ADDR_SIZE-1:0] wr_addr,
    input wire [BUS_SIZE-1:0]  wr_data
  );

  // 1. El arreglo de 2**ADDR_SIZE posiciones de BUS_SIZE bits
    reg [BUS_SIZE-1:0] mem [0:2**ADDR_SIZE-1];

  // 2. always @(posedge clk): si wr_en, escribir wr_data en wr_addr
     always @(posedge clk) begin
        if(wr_en) begin
          mem[wr_addr] <= wr_data;
        end
     end
  // 3. assign de la lectura
  assign instr = mem[addr];
  

endmodule