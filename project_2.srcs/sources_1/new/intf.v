`timescale 1ns / 1ps

module intf
    # (
        parameter BUS_SIZE = 8
    )
    (
        input wire clock,
        input wire reset,
        input wire [BUS_SIZE - 1:0] d_out,
        input wire rx_done,
        input wire tx_done,
        input wire rd,
        input wire [BUS_SIZE - 1:0] w_data,
        input wire wr,
        output reg [BUS_SIZE - 1:0] r_data,
        output reg rx_empty,
        output reg [BUS_SIZE - 1:0] d_in,
        output reg tx_start,
        output reg tx_full
    );
    
    localparam wait_for_rx_input = 3'b000;
    localparam wait_for_rd = 3'b001;
    localparam start_tx = 3'b010;
    localparam wait_tx = 3'b011;
    
    reg [2:0] state, next_state;
    reg [BUS_SIZE - 1:0] next_r_data;
    
    always @(posedge clock) begin
        if (reset) begin
            state <= wait_for_rx_input;
            next_r_data <= 0;
        end
        else begin
            state <= next_state;
            r_data <= next_r_data;
        end
    end
    
    always @(*) begin
        next_state = state;
        next_r_data = r_data;
        tx_start = 0;
        
        case (state)
            wait_for_rx_input: begin
                if (rx_done) begin
                    next_r_data = d_out;
                    next_state = wait_for_rd;
                end
            end
            wait_for_rd: begin
                if (rd) begin
                    next_state = wait_for_rx_input;
                end
            end
            start_tx: begin
                tx_start = 1;
                next_state = wait_tx;
            end
            //wait_tx: begin
               // if (tx_done) begin
                //next_state = wait_a;
                //end
            //end
            default: next_state = wait_for_rx_input;
        endcase
    end
    
endmodule
