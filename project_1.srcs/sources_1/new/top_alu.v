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
    
    reg [1:0] state, next_state;
    reg [BUS_SIZE - 1:0] reg_a, reg_b, next_a, next_b;
    reg [OP_SIZE - 1:0] reg_op, next_op;
    
    alu #(
    .BUS_SIZE(BUS_SIZE),
    .OP_SIZE(OP_SIZE)
    ) my_alu (
        .a(reg_a),
        .b(reg_b),
        .op(reg_op),
        .leds(w_data)
    );
    
    always @(posedge clock) begin
        if (reset) begin
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
        end
    end
    
    always @(*) begin
        case (state)
        load_a: begin
            if (rx_empty) begin
                next_a = r_data;
                rd = 1;
                next_state = load_b;
            end
        end
        load_b: begin
            if (rx_empty) begin
                next_b = r_data;
                rd = 1;
                next_state = load_op;
            end
        end
        load_op: begin
            if (rx_empty) begin
                next_a = r_data;
                rd = 1;
                wr = 1;
                next_state = load_a;
            end
        end
        default: next_state = load_a;
        endcase
    end
endmodule
