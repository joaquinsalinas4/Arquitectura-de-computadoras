`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/31/2026 09:43:20 PM
// Design Name: 
// Module Name: latch_if_id
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


module latch_if_id
#(
    parameter BUS_SIZE = 32
)


    (
        input wire clock,
        input wire reset, 
        input wire enable,
        input wire [BUS_SIZE -1:0] dr,
        input wire [BUS_SIZE-1:0] pc_in,
        input wire [BUS_SIZE-1:0] pc4_in,
        
        
        output reg [BUS_SIZE-1:0] pc4_out,
        output reg [BUS_SIZE-1:0] pc_out,
        output reg [BUS_SIZE-1:0] inst_out
           
    );
    
    always @(posedge clock) begin
            if(reset) begin
                pc4_out  <= 0;
                pc_out  <= 0;
                inst_out  <= 32'h00000013;   // NOP: addi x0, x0, 0
            end
            else begin
                if(enable) begin
                    pc4_out <= pc4_in;
                    pc_out <= pc_in;
                    inst_out <= dr;
                end
            end
        end
endmodule
