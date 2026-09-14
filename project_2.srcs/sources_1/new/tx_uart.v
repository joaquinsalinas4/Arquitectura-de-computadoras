`timescale 1ns / 1ps

module tx_alu
    # (
    parameter BUS_SIZE = 8
    )
    (
    input wire clock,
    input wire tx_start,
    input wire [BUS_SIZE - 1:0] d_in,
    input wire reset,
    output reg tx,
    output reg tx_done,
    input wire sample_tick
    );
    
    localparam idle = 2'b00;
    localparam start = 2'b01;
    localparam data = 2'b10;
    localparam stop = 2'b11;
    
    reg [2:0] state, next_state;
    reg [3:0] tick_reg, next_tick;
    reg [2:0] bit_reg, next_bit;
    reg [7:0] shift_reg, next_shift_reg;
    reg tx_next;
    
   always @(posedge clock) begin
        if (reset) begin
            state <= idle;
            tick_reg <= 0;
            bit_reg <= 0;
            shift_reg <= 0;
            tx <= 1;
        end 
        else begin
            state <= next_state;
            tick_reg <= next_tick;
            bit_reg <= next_bit;
            shift_reg <= next_shift_reg;
            tx <= tx_next;
        end
    end

    always @(*) begin
        next_state = state;
        next_tick = tick_reg;
        next_bit = bit_reg;
        next_shift_reg = shift_reg;
        tx_next = tx;
        tx_done = 0;
        
        case (state)
            idle: begin
                tx_next = 1;
                if (tx_start) begin
                    tx_next = 0;
                    next_state = start;
                    next_tick = 0;
                    next_shift_reg = d_in;   
                    next_bit       = 0;      
                end
            end
            start: begin
                if(sample_tick) begin
                    if (tick_reg == 15) begin
                        next_state = data;
                        next_tick = 0;
                        tx_next    = shift_reg[0];
                    end
                    else begin
                        next_tick = tick_reg + 1;
                    
                    end
                end
            end
            data: begin
                if(sample_tick) begin
                    if(tick_reg == 15) begin
                        next_tick = 0;
                        if(bit_reg == 7) begin
                            next_state = stop;
                            tx_next = 1;
                        end
                        else begin
                            next_shift_reg = {1'b0, shift_reg[BUS_SIZE-1:1]};  // corre a la derecha
                            next_bit = bit_reg + 1;
                            tx_next = shift_reg[1];
                        end
                end
                    else begin
                        next_tick = tick_reg + 1;
                    end 
                end
            end
            stop: begin
                if(sample_tick) begin
                    if(tick_reg == 15) begin
                        tx_done = 1;
                        next_tick = 0;
                        next_state = idle;
                    end
                    else begin
                        next_tick = tick_reg + 1;
                    end
                end
            end
        endcase
    end
    
endmodule