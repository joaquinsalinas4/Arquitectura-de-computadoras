`timescale 1ns / 1ps

module top_alu
    # (
        parameter BUS_SIZE = 8,
        parameter OP_SIZE = 6
    )
    (
        input wire clock,
        input wire reset,
        input wire [BUS_SIZE - 1:0] r_data,
        input wire rx_empty,
        input wire tx_full,
        output reg rd,
        output reg [BUS_SIZE - 1:0] w_data,
        output reg wr
    );
    
    localparam load_a = 2'b00;
    localparam load_b = 2'b01;
    localparam load_op = 2'b10;
    localparam send_output = 2'b11;
    
    reg next_rd, next_wr;
    reg [1:0] state, next_state;
    reg [BUS_SIZE - 1:0] reg_a, reg_b, next_a, next_b, next_w_data;
    reg [OP_SIZE - 1:0] reg_op, next_op;
    wire [BUS_SIZE-1:0] alu_result;
    
    alu #(
    .BUS_SIZE(BUS_SIZE),
    .OP_SIZE(OP_SIZE)
    ) my_alu (
        .a(reg_a),
        .b(reg_b),
        .op(reg_op),
        .leds(alu_result)
    );
    
    always @(posedge clock) begin
        if (reset) begin
            state <= load_a;
            reg_a <= 0;
            reg_b <= 0;
            reg_op <= 0;
            w_data <= 0;
            rd <= 0;
            wr <= 0;
        end
        else begin
            reg_a <= next_a;
            reg_b <= next_b;
            reg_op <= next_op;
            state <= next_state;
            rd <= next_rd;
            wr <= next_wr;
            w_data <= next_w_data;
        end
    end
    
    always @(*) begin
        next_state = state;
        next_a = reg_a;
        next_b = reg_b;
        next_op = reg_op;
        next_rd = 0;
        next_wr = 0;
        next_w_data = w_data;
    
        case (state)
        load_a: begin
            if (rx_empty == 0) begin
                next_a = r_data;
                next_rd = 1;
                next_state = load_b;
            end
        end
        load_b: begin
            if (rx_empty == 0) begin
                next_b = r_data;
                next_rd = 1;
                next_state = load_op;
            end
        end
        load_op: begin
            if (rx_empty == 0) begin
                next_op    = r_data;
                next_state = send_output;
                next_rd = 1;
            end
        end
        
        send_output: begin
            if (tx_full == 0) begin
                next_w_data = alu_result;
                next_wr     = 1;
                next_state  = load_a;
            end 
        end
        
        default: next_state = load_a;
        endcase
    end
endmodule
