`timescale 1ns / 1ps

module mem_programa
  #(
    parameter BUS_SIZE  = 32,
    parameter ADDR_SIZE = 8
  )
  (
    input wire clock,

    // Lectura (procesador, etapa IF)
    input wire [ADDR_SIZE-1:0] addr,
    output wire [BUS_SIZE-1:0]  instr,

    // Escritura (Debug Unit)
    input wire wr_en,
    input wire [ADDR_SIZE-1:0] wr_addr,
    input wire [BUS_SIZE-1:0]  wr_data
  );

  
    reg [BUS_SIZE-1:0] mem [0:2**ADDR_SIZE-1];

  
     always @(posedge clock) begin
        if(wr_en) begin
          mem[wr_addr] <= wr_data;
        end
     end
 
  assign instr = mem[addr];
  

endmodule
