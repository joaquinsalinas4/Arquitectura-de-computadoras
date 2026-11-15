`timescale 1ns / 1ps

module latch_id_ex
    #(
        parameter BUS_SIZE    = 32,
        parameter REG_SIZE    = 5,
        parameter ALU_OP_SIZE = 4
    )
    (
        input  wire clock,
        input  wire reset,
        input  wire enable,
        input  wire flush,

        // Datos desde ID
        input  wire [BUS_SIZE-1:0]    pc_in,
        input  wire [BUS_SIZE-1:0]    pc4_in,
        input  wire [BUS_SIZE-1:0]    rs1_data_in,
        input  wire [BUS_SIZE-1:0]    rs2_data_in,
        input  wire [BUS_SIZE-1:0]    imm_in,
        input  wire [REG_SIZE-1:0]    rs1_in,
        input  wire [REG_SIZE-1:0]    rs2_in,
        input  wire [REG_SIZE-1:0]    rd_in,
        input  wire [2:0]             funct3_in,
        input  wire [6:0]             funct7_in,
        input  wire [BUS_SIZE-1:0]    inst_in,      // solo para depuración

        // Control para EX
        input  wire                   alu_src_in,
        input  wire [ALU_OP_SIZE-1:0] alu_op_in,
        input  wire                   branch_in,
        input  wire                   jump_in,
        // Control para MEM
        input  wire                   mem_read_in,
        input  wire                   mem_write_in,
        // Control para WB
        input  wire                   reg_write_in,
        input  wire [1:0]             mem_to_reg_in,

        // Salidas hacia EX
        output reg  [BUS_SIZE-1:0]    pc_out,
        output reg  [BUS_SIZE-1:0]    pc4_out,
        output reg  [BUS_SIZE-1:0]    rs1_data_out,
        output reg  [BUS_SIZE-1:0]    rs2_data_out,
        output reg  [BUS_SIZE-1:0]    imm_out,
        output reg  [REG_SIZE-1:0]    rs1_out,
        output reg  [REG_SIZE-1:0]    rs2_out,
        output reg  [REG_SIZE-1:0]    rd_out,
        output reg  [2:0]             funct3_out,
        output reg  [6:0]             funct7_out,
        output reg  [BUS_SIZE-1:0]    inst_out,

        output reg                    alu_src_out,
        output reg  [ALU_OP_SIZE-1:0] alu_op_out,
        output reg                    branch_out,
        output reg                    jump_out,
        output reg                    mem_read_out,
        output reg                    mem_write_out,
        output reg                    reg_write_out,
        output reg  [1:0]             mem_to_reg_out
    );

    always @(posedge clock) begin
        if (reset) begin
            pc_out         <= 0;
            pc4_out        <= 0;
            rs1_data_out   <= 0;
            rs2_data_out   <= 0;
            imm_out        <= 0;
            rs1_out        <= 0;
            rs2_out        <= 0;
            rd_out         <= 0;
            funct3_out     <= 0;
            funct7_out     <= 0;
            inst_out       <= 32'h00000013;   // NOP: addi x0, x0, 0
            alu_src_out    <= 0;
            alu_op_out     <= 0;
            branch_out     <= 0;
            jump_out       <= 0;
            mem_read_out   <= 0;
            mem_write_out  <= 0;
            reg_write_out  <= 0;
            mem_to_reg_out <= 0;
        end
        else if (enable) begin
            if (flush) begin
                // Burbuja: las señales que producen efectos quedan en 0
                inst_out       <= 32'h00000013;
                branch_out     <= 0;
                jump_out       <= 0;
                mem_read_out   <= 0;
                mem_write_out  <= 0;
                reg_write_out  <= 0;
            end
            else begin
                pc_out         <= pc_in;
                pc4_out        <= pc4_in;
                rs1_data_out   <= rs1_data_in;
                rs2_data_out   <= rs2_data_in;
                imm_out        <= imm_in;
                rs1_out        <= rs1_in;
                rs2_out        <= rs2_in;
                rd_out         <= rd_in;
                funct3_out     <= funct3_in;
                funct7_out     <= funct7_in;
                inst_out       <= inst_in;
                alu_src_out    <= alu_src_in;
                alu_op_out     <= alu_op_in;
                branch_out     <= branch_in;
                jump_out       <= jump_in;
                mem_read_out   <= mem_read_in;
                mem_write_out  <= mem_write_in;
                reg_write_out  <= reg_write_in;
                mem_to_reg_out <= mem_to_reg_in;
            end
        end
    end

endmodule
