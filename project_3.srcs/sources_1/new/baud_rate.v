`timescale 1ns / 1ps

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