module imm_gen
#(
    parameter BUS_SIZE = 32,
    parameter OPCODE_SIZE = 7
    )
(
    input wire [BUS_SIZE-1:0] instr,
    output reg [BUS_SIZE-1:0] inmediato

    );
    
    localparam tipo_I = 7'b0010011;
    localparam tipo_load = 7'b0000011;
    localparam tipo_jalr = 7'b1100111;
    
    
    localparam tipo_S = 7'b0100011; //sb, sh,sw
    localparam tipo_B = 7'b1100011; //beq, bne
    localparam tipo_U = 7'b0110111; //lui
    localparam tipo_J = 7'b1101111; //jal
    
  
    always @(*) begin
        case(instr[OPCODE_SIZE - 1:0])
            tipo_I,tipo_load, tipo_jalr:
                inmediato = {{20{instr[31]}}, instr[31:20]};
            tipo_S:
                inmediato = {{20{instr[31]}},instr[31:25], instr[11:7] };
            tipo_B:
                inmediato = {{19{instr[31]}},instr[31], instr[7], instr[30:25], instr[11:8], 1'b0};
            tipo_U:
                inmediato = {instr[31:12], 12'b0};
            tipo_J:
                inmediato = {{11{instr[31]}} ,instr[31], instr[19:12], instr[20], instr[30:21], 1'b0};
            default:
                inmediato = 0;
        endcase
    end
endmodule
