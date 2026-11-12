`timescale 1ns / 1ps

module banco_registros
    #(
        parameter BUS_SIZE = 32,
        parameter ADDR_SIZE  = 5

    )
    (
        input wire clock, 
        input wire reset,
        input wire enable,
        
        //Lectura
        input wire [ADDR_SIZE-1:0] rs1_addr,
        input wire [ADDR_SIZE-1:0] rs2_addr,
        output wire [BUS_SIZE-1:0]    rs1_data,
        output wire [BUS_SIZE-1:0]    rs2_data,
        
        //Escritura
        input wire reg_write,
        input wire [ADDR_SIZE-1:0] rd_addr,
        input wire [BUS_SIZE-1:0] wr_data,
        
        //Debug Unit
        input wire [ADDR_SIZE-1:0] dbg_addr,
        output wire [BUS_SIZE-1:0] dbg_data
       );
       
       reg [BUS_SIZE-1:0] regs [0:31];
       
       integer i;
       
       always @(negedge clock) begin
            if(reset) begin
                for(i=0; i < 32; i = i+1) 
                    regs[i] <= 0;
            end
            else if(enable && reg_write && rd_addr !=0) begin
                regs[rd_addr] <= wr_data;
            end
       end
       
       assign rs1_data = regs[rs1_addr];
       assign rs2_data = regs[rs2_addr];
       assign dbg_data = regs[dbg_addr];
       
endmodule
