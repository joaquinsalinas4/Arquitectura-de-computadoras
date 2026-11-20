`timescale 1ns / 1ps

module control_unit
#(
    parameter OPCODE_SIZE = 7
)
(
    input wire [OPCODE_SIZE - 1: 0] opcode,
    
    //EX
    output reg ALUsrc, //rs2 (0), inmediato (1)
    output reg [2:0] ALUop, //ADD, SUB, LUI, R, I
    
    //MEM
    output reg memRead, // si hay que leer la memoria
    output reg memWrite, // si hay que escribir la memoria
    output reg branch, //si la instruccion es un salto condicional
    output reg jump, //si es un salto incondicional 

    
    //WB
    output reg [1:0] wb_sel, // elige que se guarda en el registro. ALU, memoria o PC+4
    output reg regWrite //si la instruccion guarda un resultado en un registro
    );
    
    localparam OP_LOAD = 7'b0000011;
    localparam OP_STORE = 7'b0100011;
    localparam OP_LUI = 7'b0110111;
    localparam OP_BRANCH = 7'b1100011;
    localparam OP_JAL = 7'b1101111;
    localparam OP_JALR = 7'b1100111;
    localparam OP_R = 7'b0110011;
    localparam OP_I = 7'b0010011;
    
    
    // Valores de ALUop 
    localparam ALUOP_ADD = 3'b000;   // siempre sumar (load, store, jalr)
    localparam ALUOP_SUB = 3'b001;   // siempre restar (branch)
    localparam ALUOP_LUI = 3'b010;   // copiar el inmediato (lui)
    localparam ALUOP_R   = 3'b011;   // tipo R: mirar funct3 y funct7
    localparam ALUOP_I   = 3'b100;   // tipo I: mirar funct3
    
    // Valores de wb_sel 
    localparam WB_ALU = 2'b00;   // el resultado de la ALU
    localparam WB_MEM = 2'b01;   // lo leído de memoria
    localparam WB_PC4 = 2'b10;   // PC + 4 (jal, jalr)
    
    always @(*) begin
        ALUsrc = 0;
        ALUop = ALUOP_ADD;
        memRead = 0;
        memWrite = 0;
        branch = 0;
        jump = 0;
        wb_sel = WB_ALU;
        regWrite = 0;
        
        case(opcode) 
            OP_LOAD: begin
                ALUsrc = 1;
                ALUop = ALUOP_ADD;
                memRead = 1;
                wb_sel = WB_MEM;
                regWrite = 1;
            end
            
            OP_STORE: begin
                ALUsrc = 1;
                ALUop = ALUOP_ADD;
                memWrite = 1;
            end
            
            OP_LUI: begin
                ALUsrc = 1;
                ALUop = ALUOP_LUI;
                wb_sel = WB_ALU;
                regWrite = 1;
            end
            
            OP_BRANCH: begin
                ALUop  = ALUOP_SUB;
                branch = 1;
            end
            
            OP_JAL: begin
                jump = 1;
                wb_sel = WB_PC4;
                regWrite = 1;
            end
            
            OP_JALR: begin
                ALUsrc = 1;
                ALUop = ALUOP_ADD;
                jump = 1;
                wb_sel = WB_PC4;
                regWrite = 1;
            end
            
            OP_R: begin
                ALUsrc = 0;
                ALUop = ALUOP_R;
                wb_sel = WB_ALU;
                regWrite = 1;
            end
            
            OP_I: begin
                ALUsrc = 1;
                ALUop = ALUOP_I;
                wb_sel = WB_ALU;
                regWrite = 1;
            end
            
        endcase
    end
    
endmodule
