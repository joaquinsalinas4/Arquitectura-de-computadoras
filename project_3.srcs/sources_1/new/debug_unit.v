`timescale 1ns / 1ps

module debug_unit
  #(
    parameter BUS_SIZE     = 32,
    parameter ADDRESS_SIZE = 8,
    parameter BYTE_SIZE    = 8
  )
  (
    input  wire clock,
    input  wire reset,

    // UART RX
    input  wire rx_done,
    input  wire [BYTE_SIZE-1:0]    rx_data,

    // UART TX
    output wire tx_start,
    output reg  [BYTE_SIZE-1:0]    tx_data,
    input  wire tx_done,

    // Memoria de programa
    output wire mem_wr_en,
    output wire [ADDRESS_SIZE-1:0] mem_wr_addr,
    output wire [BUS_SIZE-1:0]     mem_wr_data,

    // Procesador
    output wire cpu_enable,
    input  wire [BUS_SIZE-1:0] pc,
    input  wire [BUS_SIZE-1:0] if_id_instr
  );

  // Estados
  localparam [2:0] IDLE  = 3'b000,
                   LOAD  = 3'b001,
                   WRITE = 3'b010,
                   STEP  = 3'b011,
                   SEND  = 3'b100,
                   SEND_WAIT = 3'b101;
                   

  // Comandos
  localparam CMD_LOAD = 8'h4C;   // 'L'
  localparam CMD_STEP = 8'h53;   // 'S'

  localparam HALT = 32'hFFFFFFFF;

  // Registros
  reg [2:0] state, next_state;
  reg [BUS_SIZE-1:0] instr_buffer, next_instr_buffer;
  reg [1:0] byte_count, next_byte_count;
  reg [ADDRESS_SIZE-1:0] addr_count, next_addr_count;
  reg [2:0] tx_count, next_tx_count;     // 

  // Secuencial
  always @(posedge clock) begin
      if (reset) begin
        state        <= IDLE;
        instr_buffer <= 0;
        byte_count   <= 0;
        addr_count   <= 0;
        tx_count     <= 0;            
      end
      else begin
        state        <= next_state;
        instr_buffer <= next_instr_buffer;
        byte_count   <= next_byte_count;
        addr_count   <= next_addr_count;
        tx_count     <= next_tx_count; 
      end
  end

  always @(*) begin
    
    next_state        = state;
    next_instr_buffer = instr_buffer;
    next_byte_count   = byte_count;
    next_addr_count   = addr_count;
    next_tx_count = tx_count;

    case (state)
      IDLE: begin
        if (rx_done) begin
          case (rx_data)
            CMD_LOAD: begin
              next_state      = LOAD;
              next_byte_count = 0;   
              next_addr_count = 0;
            end
            CMD_STEP: begin
              next_state = STEP;
            end
            default: begin
              next_state = IDLE;
            end
          endcase
        end
      end

      LOAD: begin
        if (rx_done) begin
          next_instr_buffer = {instr_buffer[23:0], rx_data};
          next_byte_count   = byte_count + 1;
          if (byte_count == 3)
            next_state = WRITE;
        end
      end

      WRITE: begin
        next_addr_count = addr_count + 1;   // se mueve una posición
        if (instr_buffer == HALT)
          next_state = IDLE;                // terminó la carga
        else
          next_state = LOAD;                //no termino 
      end
      
      STEP: begin
        next_state =  SEND;
        next_tx_count = 0;
      end
      
      SEND: begin
        next_state = SEND_WAIT;
      end
      
      SEND_WAIT: begin
        if(tx_done) begin
            if(tx_count == 7) begin
                next_state = IDLE;
            end
            else begin
                next_tx_count = tx_count + 1;
                next_state = SEND;
            end
        end
      end

      default: next_state = IDLE;  
    endcase
  end

  always @(*) begin
    case(tx_count)
        0: tx_data = pc[31:24];
        1: tx_data = pc[23:16];
        2: tx_data = pc[15:8];
        3: tx_data = pc[7:0];
        4: tx_data = if_id_instr[31:24];
        5: tx_data = if_id_instr[23:16];
        6: tx_data = if_id_instr[15:8];
        7: tx_data = if_id_instr[7:0];
  endcase
  end

  assign mem_wr_en   = (state == WRITE);
  assign mem_wr_addr = addr_count;
  assign mem_wr_data = instr_buffer;
  assign cpu_enable = (state == STEP);
  assign tx_start = (state == SEND);

endmodule
