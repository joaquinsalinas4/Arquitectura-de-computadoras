`timescale 1ns / 1ps

module debug_unit 
# (
        parameter BUS_SIZE = 32,
        parameter ADDRESS_SIZE = 8
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
        output reg tx_full,

        // Nuevas salidas (para memoria de datos)
        output reg [BUS_SIZE - 1:0] wr_data,
        output reg wr_en,
        output reg [ADDRESS_SIZE - 1:0] wr_address;
    );
    
    reg state_rx, next_state_rx, state_tx, next_state_tx;
    reg [BUS_SIZE - 1:0] next_r_data, next_d_in;
    reg next_rx_empty, next_tx_full, next_tx_start;
    
    // Codigos del programa
    localparam start_cmd = 8'b00010001;
    localparam halt_cmd = 8'b00010000;
    localparam write_mem_cmd = 8'b00011111;
    localparam step_cmd = 8'b11010001;
    
    // Estados RX
    localparam wait_for_command = 4'b0000;
    localparam start_rx = 4'b0001;
    localparam rx_halt = 4'b0010;
    localparam rx_write_mem = 4'b0011;
    localparam rx_step = 4'b0100;

    // Estados write_mem
    localparam

    // TP PASADO (capaz los borramos)
    localparam wait_for_rx_input = 1'b0;
    localparam wait_for_rd = 1'b1;
    // Estados TX
    localparam tx_wait_wr = 1'b0;
    localparam tx_wait_tx_done = 1'b1;

    // Nuevos registros
    reg [ADDRESS_SIZE - 1:0] pos_mem, next_pos_mem;

    
    // Secuencial RX (RX -> ALU)
    always @(posedge clock) begin
        if (reset) begin
            state_rx <= wait_for_command;
            r_data <= 0;
            rx_empty <= 1;
        end
        else begin
            state_rx <= next_state_rx;
            r_data <= next_r_data;
            rx_empty <= next_rx_empty;
        end
    end
    
    // Combinacional RX - Comandos Debug Unit
    always @(*) begin
        case (state_rx)
            wait_for_command: begin
                if (rx_done) begin
                    case (d_out)
                        start_cmd: begin
                            next_state_rx = start_rx;
                        end
                        halt_cmd: begin
                            next_state_rx = rx_halt;
                        end
                        write_mem_cmd: begin
                            next_state_rx = rx_write_mem;
                        end
                        step_cmd: begin
                            next_state_rx = rx_step;
                        end
                    endcase
                    // next_rx_empty = 0;
                end
            end
            rx_write_mem: begin
                if (rx_done) begin
                    wr_data = d_out;
                    next_pos_mem = next_pos_mem + 8;
                    wr_addr = pos_mem;
                    wr_en = 1;
                end
            end
            default: next_state_rx = wait_for_command;
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
        next_state_tx = state_tx;
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
            default: next_state_tx = tx_wait_wr;
        endcase
    end
endmodule
