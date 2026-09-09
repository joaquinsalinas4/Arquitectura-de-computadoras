`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/05/2026 07:31:37 PM
// Design Name: 
// Module Name: tb_alu
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


module tb_alu;
    reg [7:0] switches;
    reg en_a, en_b, en_op, clock;
    reg [5:0] opcodes [0:7];   
    wire [7:0] leds;
    integer i, idx;
    
    
    top #(
    .BUS_SIZE(8),
    .OP_SIZE(6)
    ) my_top(.switches(switches),
    .en_a(en_a),
    .en_b(en_b),
    .en_op(en_op),
    .clock(clock),
    .leds(leds));  
    
    initial clock = 0;
    always #5 clock = ~clock;
    
    reg [7:0] reg_a, reg_b, reg_op;
    
    initial begin
        opcodes[0] = 6'b100000; // ADD
        opcodes[1] = 6'b100010; // SUB
        opcodes[2] = 6'b100100; // AND
        opcodes[3] = 6'b100101; // OR
        opcodes[4] = 6'b100110; // XOR
        opcodes[5] = 6'b000011; // SRA
        opcodes[6] = 6'b000010; // SRL
        opcodes[7] = 6'b100111; // NOR
        for (i = 0; i < 30; i = i + 1) begin
            switches = $random;
            en_a = 1;
            reg_a = switches;
            #20;
            en_a = 0;
            switches = $random;
            en_b = 1;
            reg_b = switches;
            #20;
            en_b = 0;
            idx = $random % 8;
            if(idx < 0) begin
                idx = idx + 8;
             end
                
            switches = opcodes[idx];
            en_op = 1;
            reg_op = switches;
            #20;
            en_op = 0;
            $display("A = %b, B = %b, Op = %b, leds = %b", reg_a, reg_b, reg_op, leds);
        end
        
        
       

        $display("Simulacion terminada.");
        $finish;
       end
    
   
   
endmodule

