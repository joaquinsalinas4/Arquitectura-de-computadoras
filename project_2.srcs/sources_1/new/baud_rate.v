`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/14/2026 07:37:37 PM
// Design Name: 
// Module Name: baud_rate
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


module baud_rate
#(
    parameter integer ciclos = 325,
    parameter integer N = 9
)(
    input  wire clock,
    output reg  tick,
    input  wire reset
);
reg [N-1:0] contador_tick;

always @(posedge clock) begin
    if (reset) begin
        contador_tick <= 0;
        tick <= 0;
    end
    else begin
        contador_tick <= (contador_tick == ciclos) ? 0 : contador_tick + 1;
        tick <= (contador_tick == ciclos) ? 1'b1 : 1'b0;
    end
end


endmodule
