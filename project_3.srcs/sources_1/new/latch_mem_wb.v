`timescale 1ns / 1ps

module latch_mem_wb
    #(
        parameter BUS_SIZE = 32,
        parameter REG_SIZE = 5
    )
    (
        input wire clock,
        input wire reset,
        input wire enable,
        input wire [BUS_SIZE-1:0] mem_data_in,
        input wire [BUS_SIZE-1:0] alu_result_in,
        input wire [BUS_SIZE-1:0] pc4_in,
        input wire [REG_SIZE-1:0] rd_in,
        input wire [BUS_SIZE-1:0] inst_in,
        input wire                regWrite_in,
        input wire [1:0]          wb_sel_in,
        output reg [BUS_SIZE-1:0] mem_data_out,
        output reg [BUS_SIZE-1:0] alu_result_out,
        output reg [BUS_SIZE-1:0] pc4_out,
        output reg [REG_SIZE-1:0] rd_out,
        output reg [BUS_SIZE-1:0] inst_out,
        output reg                regWrite_out,
        output reg [1:0]          wb_sel_out
    );

    always @(posedge clock) begin
        if (reset) begin
            mem_data_out   <= 0;
            alu_result_out <= 0;
            pc4_out        <= 0;
            rd_out         <= 0;
            inst_out       <= 32'h00000013;   // NOP
            regWrite_out   <= 0;
            wb_sel_out     <= 0;
        end
        else if (enable) begin
            mem_data_out   <= mem_data_in;
            alu_result_out <= alu_result_in;
            pc4_out        <= pc4_in;
            rd_out         <= rd_in;
            inst_out       <= inst_in;
            regWrite_out   <= regWrite_in;
            wb_sel_out     <= wb_sel_in;
        end
    end

endmodule