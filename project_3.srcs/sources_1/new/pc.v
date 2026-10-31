`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/31/2026 08:53:15 PM
// Design Name: 
// Module Name: pc
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

module pc 
#(
    parameter BUS_SIZE = 32
    )
    (
     input wire clock,
     input wire reset,
     input wire enable,
     input wire [BUS_SIZE-1:0] next_pc,
     output reg [BUS_SIZE-1:0] pc
     
    );
   
    
    always @(posedge clock) begin
        if(reset) begin
            pc <= 0;
         end
         else if (enable) begin
            pc <= next_pc;
        end   
    end
    
    
endmodule
