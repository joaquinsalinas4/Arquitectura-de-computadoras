`timescale 1ns / 1ps

module rx_uart
#(
    parameter integer ticks = 16,
    parameter integer bits = 8
)(
    input wire clock,
    input wire reset,
    input wire rx,
    input wire sample_tick,
    output reg rx_done,
    output reg [bits-1:0] dout
);
   localparam [1:0] idle = 2'b00,
                   start = 2'b01,
                   data = 2'b10,
                   stop = 2'b11;
                   
    reg [1:0] state = idle;
    reg [1:0] next_state;
    reg [3:0] count_tick;
    reg [bits - 1: 0] shift_reg;
    reg [bits -1: 0] count_bits;
    
    always @(posedge clock) begin
        state <= next_state;
     end
    
    always @(*) begin
    case (state)
        idle: begin
            if (rx == 0) begin
                next_state = start;
            end
            else begin
                next_state = idle;
            end
        end
        start: begin
            if(count_tick == 7) begin
                next_state = data;
            end
            else begin
                next_state = start;
            end
        end
        
        data: begin
            if(count_tick == 15 && count_bits == bits - 1) begin
                next_state = stop;
            end
            else begin
                next_state = data;
            end
        end
        
        stop: begin
            if (count_tick == 15) begin
                next_state = idle;
            end
            else begin
                next_state = stop;
            end
        end
               
        default: next_state = idle;
    endcase
    
end

always @(posedge clock) begin
    case(state)
        idle: begin
            count_tick <= 0;
            rx_done    <= 0;
            count_bits <= 0;
        end
        start: begin
            if(sample_tick) begin
             count_tick <= (count_tick == 7) ? 0: count_tick + 1;
            end
       end
       data: begin
             if(sample_tick) begin
                if(count_tick == 15) begin
                    count_tick <= 0;
                    shift_reg <= {shift_reg[6:0], rx};
                    count_bits <= count_bits + 1;
                end
                else begin
                    count_tick <= count_tick + 1;
                end
            end
       end
       stop: begin
            if(sample_tick) begin
                if(count_tick == 15) begin
                    count_tick <= 0;
                    rx_done <= 1;
                    dout <= shift_reg;
                end
                else begin
                    count_tick <= count_tick + 1;
                    rx_done    <= 0;
                end
             end
       end
        
                    
    endcase
    
end
            
endmodule
