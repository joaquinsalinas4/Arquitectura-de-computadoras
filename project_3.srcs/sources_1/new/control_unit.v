`timescale 1ns / 1ps

module control_unit
    #(
        parameter BUS_SIZE = 32
    )
    (
        input wire [BUS_SIZE-1:0] instruction,
        output reg alu_src, // 0 = rs2, 1 = inmediato
        output reg alu_op, 
        output reg mem_read,
        output reg mem_write,
        output reg mem_to_reg,
        output reg branch,
        output reg jump
    );

    localparam OP_R      = 7'b0110011;
    localparam OP_I_ARIT = 7'b0010011;
    localparam OP_LOAD   = 7'b0000011;
    localparam OP_JALR   = 7'b1100111;
    localparam OP_S      = 7'b0100011;
    localparam OP_B      = 7'b1100011;
    localparam OP_LUI    = 7'b0110111;
    localparam OP_JAL    = 7'b1101111;

    // opcode
    always @(*) begin
        case(instruction[6:0])
            OP_R: begin
                alu_src = 0;
                mem_read = 0;
                mem_write = 0;
                mem_to_reg = 0;
                reg_write = 1;
                branch = 0;
                jump = 0;
            end
        endcase
    end

    // funct3
    always @(*) begin
        case(instruction[6:0])

        endcase
    end
    
    // funct7
    always @(*) begin
        case(instruction[6:0])

        endcase
    end
endmodule
