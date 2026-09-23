`timescale 1ns / 1ps

module interfaz
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
    
    reg state_rx, next_state_rx, state_tx, next_state_tx;
    reg [BUS_SIZE - 1:0] next_r_data, next_d_in;
    reg next_rx_empty, next_tx_full, next_tx_start;
    
    // Estados RX
    localparam wait_for_rx_input = 1'b0;
    localparam wait_for_rd = 1'b1;
    // Estados TX
    localparam tx_wait_wr = 1'b0;
    localparam tx_wait_tx_done = 1'b1;
    
    // Secuencial RX (RX -> ALU)
    always @(posedge clock) begin
        if (reset) begin
            state_rx <= wait_for_rx_input;
            r_data <= 0;
            rx_empty <= 1;
        end
        else begin
            state_rx <= next_state_rx;
            r_data <= next_r_data;
            rx_empty <= next_rx_empty;
        end
    end
    
    // Combinacional RX
    always @(*) begin
        next_state_rx = state_rx;
        next_r_data = r_data;
        next_rx_empty = rx_empty;
        
        case (state_rx)
            wait_for_rx_input: begin
                if (rx_done) begin
                    next_r_data = d_out;
                    next_state_rx = wait_for_rd;
                    next_rx_empty = 0;
                end
            end
            wait_for_rd: begin
                if (rd) begin
                    next_state_rx = wait_for_rx_input;
                    next_rx_empty = 1;
                end
            end
            default: next_state_rx = wait_for_rx_input;
        endcase
    end
    
    // Secuencial TX (ALU -> TX)
    always @(posedge clock) begin
        if (reset) begin
            state_tx <= tx_wait_wr;
            tx_full <= 0;
            tx_start <= 0;
            d_in <= 0;
        end
        else begin
            state_tx <= next_state_tx;
            tx_full <= next_tx_full;
            tx_start <= next_tx_start;
            d_in <= next_d_in;
        end
    end
    
    // Combinacional TX
    always @(*) begin
        next_tx_full = tx_full;
        next_tx_start = 0;
        next_d_in = d_in;
        
        case (state_tx)
            tx_wait_wr: begin
                if (wr == 1) begin
                    next_d_in = w_data;
                    next_tx_full = 1;
                    next_tx_start = 1;
                    next_state_tx = tx_wait_tx_done;
                end
            end
            tx_wait_tx_done: begin
                if (tx_done) begin
                    next_tx_full = 0;
                    next_state_tx = tx_wait_wr;
                end
            end
        endcase
    end
    
endmodule
