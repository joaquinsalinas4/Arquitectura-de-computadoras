`timescale 1ns / 1ps

module rx_uart
#(
    parameter integer ticks = 16,   // oversampling: ticks por bit
    parameter integer bits  = 8     // bits de datos
)(
    input  wire             clock,
    input  wire             reset,
    input  wire             rx,
    input  wire             sample_tick,
    output reg              rx_done,    // pulso de 1 ciclo al terminar el byte
    output wire [bits-1:0]  dout        // válido cuando rx_done = 1 (y después)
);

    localparam [1:0] idle  = 2'b00,
                     start = 2'b01,
                     data  = 2'b10,
                     stop  = 2'b11;

    // ---------- Sincronizador de 2 FF (rx es asincrónica) ----------
    // Arrancan en 1 (línea en idle) para no detectar un start falso al encender
    reg rx_meta = 1'b1;
    reg rx_sync = 1'b1;
    always @(posedge clock) begin
        rx_meta <= rx;
        rx_sync <= rx_meta;
    end

    // ---------- Registros ----------
    reg [1:0]              state,     next_state;
    reg [3:0]              tick_reg,  next_tick;
    reg [$clog2(bits)-1:0] bit_reg,   next_bit;
    reg [bits-1:0]         shift_reg, next_shift;

    // El byte recibido: en el ciclo de rx_done, shift_reg ya tiene los 8 bits
    assign dout = shift_reg;

    // ---------- Secuencial ----------
    always @(posedge clock) begin
        if (reset) begin
            state     <= idle;
            tick_reg  <= 0;
            bit_reg   <= 0;
            shift_reg <= 0;
        end
        else begin
            state     <= next_state;
            tick_reg  <= next_tick;
            bit_reg   <= next_bit;
            shift_reg <= next_shift;
        end
    end

    // ---------- Combinacional ----------
    // Regla clave: TODO avance (de contador o de estado) ocurre solo cuando hay sample_tick
    always @(*) begin
        next_state = state;
        next_tick  = tick_reg;
        next_bit   = bit_reg;
        next_shift = shift_reg;
        rx_done    = 1'b0;

        case (state)
            idle: begin
                if (rx_sync == 1'b0) begin          // flanco del start bit
                    next_state = start;
                    next_tick  = 0;
                end
            end

            start: begin
                if (sample_tick) begin
                    if (tick_reg == (ticks/2 - 1)) begin   // mitad del start bit
                        next_state = data;
                        next_tick  = 0;
                        next_bit   = 0;
                    end
                    else
                        next_tick = tick_reg + 1;
                end
            end

            data: begin
                if (sample_tick) begin
                    if (tick_reg == (ticks - 1)) begin      // mitad del bit de dato
                        next_tick  = 0;
                        next_shift = {rx_sync, shift_reg[bits-1:1]};  // LSB primero: entra por arriba y corre a la derecha
                        if (bit_reg == (bits - 1))
                            next_state = stop;
                        else
                            next_bit = bit_reg + 1;
                    end
                    else
                        next_tick = tick_reg + 1;
                end
            end

            stop: begin
                if (sample_tick) begin
                    if (tick_reg == (ticks - 1)) begin      // mitad del stop bit
                        next_state = idle;
                        rx_done    = 1'b1;
                    end
                    else
                        next_tick = tick_reg + 1;
                end
            end

            default: next_state = idle;
        endcase
    end

endmodule
