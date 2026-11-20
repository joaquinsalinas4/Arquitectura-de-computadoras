`timescale 1ns / 1ps

module control_alu
#(
    parameter ALU_SIZE = 3,
    parameter ALUCTRL_SIZE = 4
)

(
    input wire [ALU_SIZE-1:0] alu_op,
    input wire [2:0] funct3,
    input wire bit30,
    output reg [ALUCTRL_SIZE-1: 0] alu_ctrl
    );
    
    // Valores de ALUop 
    localparam ALUOP_ADD = 3'b000;   // siempre sumar (load, store, jalr)
    localparam ALUOP_SUB = 3'b001;   // siempre restar (branch)
    localparam ALUOP_LUI = 3'b010;   // copiar el inmediato (lui)
    localparam ALUOP_R   = 3'b011;   // tipo R: mirar funct3 y funct7
    localparam ALUOP_I   = 3'b100;   // tipo I: mirar funct3
    
    localparam ADD = 4'b0000;
    localparam SUB = 4'b0001;
    localparam AND = 4'b0010;
    localparam OR = 4'b0011;
    localparam XOR = 4'b0100;
    localparam SRA = 4'b0101;
    localparam SRL = 4'b0110;
    localparam SLL = 4'b0111;
    localparam SLT= 4'b1000;
    localparam SLTU = 4'b1001;
    localparam COPY_B = 4'b1010;
    
    //FUNCT3
    localparam FUNCT3_ADD_SUB = 3'b000;
    localparam FUNCT3_SLL = 3'b001;
    localparam FUNCT3_SLT = 3'b010;
    localparam FUNCT3_SLTU = 3'b011;
    localparam FUNCT3_XOR =  3'b100;
    localparam FUNCT3_SRL_SRA = 3'b101;
    localparam FUNCT3_OR = 3'b110;
    localparam FUNCT3_AND = 3'b111;
    
    always @(*) begin
        alu_ctrl = ADD;
        case(alu_op)
            ALUOP_ADD: begin
                alu_ctrl = ADD;
            end
            ALUOP_SUB: begin
                alu_ctrl = SUB;
            end
            ALUOP_LUI: begin
                alu_ctrl = COPY_B;
            end
            ALUOP_R: begin
                case(funct3)
                    FUNCT3_ADD_SUB: begin
                        alu_ctrl = bit30? SUB: ADD;
                    end
                    FUNCT3_SLL: begin
                        alu_ctrl = SLL;
                    end
                    FUNCT3_SLT: begin
                        alu_ctrl = SLT;
                    end
                    FUNCT3_SLTU: begin
                        alu_ctrl = SLTU;
                    end
                    FUNCT3_XOR: begin
                        alu_ctrl = XOR;
                    end
                    FUNCT3_SRL_SRA: begin
                        alu_ctrl = bit30? SRA : SRL;
                    end
                    FUNCT3_OR: begin
                        alu_ctrl = OR;
                    end
                    FUNCT3_AND: begin
                        alu_ctrl = AND;
                    end
                endcase
            end
            ALUOP_I: begin
                case(funct3)
                    FUNCT3_ADD_SUB: begin
                        alu_ctrl = ADD;                  
                    end
                    FUNCT3_SLL: begin
                        alu_ctrl = SLL;                 
                    end
                    FUNCT3_SLT: begin
                        alu_ctrl = SLT;                  
                    end
                    FUNCT3_SLTU: begin
                        alu_ctrl = SLTU;                 
                    end
                    FUNCT3_XOR: begin
                        alu_ctrl = XOR;                  
                    end
                    FUNCT3_SRL_SRA: begin
                        alu_ctrl = bit30 ? SRA : SRL;    
                    end
                    FUNCT3_OR: begin
                        alu_ctrl = OR;                  
                    end
                    FUNCT3_AND: begin
                        alu_ctrl = AND;                  
                    end
                endcase
            end 
        endcase
    end
endmodule