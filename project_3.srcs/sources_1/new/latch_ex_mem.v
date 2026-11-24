`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 23.11.2026 20:42:10
// Design Name: 
// Module Name: latch_ex_mem
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


module latch_ex_mem
    #(
        parameter BUS_SIZE = 32,
        parameter REG_SIZE = 5
    )


    (
        //Entradas
        input wire clock,
        input wire reset,
        input wire enable,
        input wire memRead_in,
        input wire memWrite_in,
        input wire regWrite_in,
        input wire [BUS_SIZE-1 : 0] alu_result_in,
        input wire [BUS_SIZE-1 : 0] rs2_data_in,
        input wire [REG_SIZE-1: 0] rd_in,
        input  wire [BUS_SIZE-1:0]    pc4_in,
        input wire [1:0] wb_sel_in,
        input wire [2:0] funct3_in,
        input wire [BUS_SIZE -1: 0] inst_in,

        
        
        //Salidas
        output reg [BUS_SIZE-1 : 0] rs2_data_out,
        output reg [BUS_SIZE-1 : 0] alu_result_out,
        output reg memRead_out,
        output reg memWrite_out,
        output reg regWrite_out,
        output reg [REG_SIZE-1: 0] rd_out,
        output reg [BUS_SIZE-1: 0] pc4_out,
        output reg [1:0] wb_sel_out,
        output reg [2:0] funct3_out,
        output reg [BUS_SIZE -1: 0] inst_out
    );
    
    always @(posedge clock) begin
        if(reset) begin 
            rs2_data_out <=0;
            alu_result_out <=0;
            memRead_out <=0;
            memWrite_out <=0;
            regWrite_out <=0;
            rd_out <=0;
            pc4_out <=0;
            wb_sel_out <=0;
            funct3_out <=0;
            inst_out <=32'h00000013;
        end
        else if(enable) begin
            rs2_data_out <= rs2_data_in;
            alu_result_out <= alu_result_in;
            memRead_out <= memRead_in;
            memWrite_out <= memWrite_in;
            regWrite_out <= regWrite_in;
            rd_out <= rd_in;
            pc4_out <= pc4_in;
            wb_sel_out <= wb_sel_in;
            funct3_out <= funct3_in;
            inst_out <= inst_in;
        end
       
    end
endmodule
