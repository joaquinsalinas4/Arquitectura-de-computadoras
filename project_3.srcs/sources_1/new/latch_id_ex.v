`timescale 1ns / 1ps

module latch_id_ex
    #(
        parameter BUS_SIZE = 32
    )
    (
        input wire clock,
        input wire reset, 
        input wire enable,
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
