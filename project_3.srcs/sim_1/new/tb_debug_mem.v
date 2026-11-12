`timescale 1ns / 1ps

module tb_debug_mem;

  localparam BUS_SIZE     = 32;
  localparam ADDRESS_SIZE = 8;
  localparam BYTE_SIZE    = 8;

  localparam [7:0]  CMD_LOAD = 8'h4C;   // 'L'
  localparam [7:0]  CMD_STEP = 8'h53;   // 'S'
  localparam [31:0] HALT     = 32'hFFFFFFFF;

  // Cuántos ciclos dura rx_done y cuánto se espera entre bytes
  // (probá RX_DONE_CYCLES = 1, 2 o 3 para ver cómo reacciona la FSM)
  localparam RX_DONE_CYCLES = 1;
  localparam GAP_CYCLES     = 4;

  // Estímulos (los maneja el testbench)
  reg clock = 0;
  reg reset = 1;
  reg rx_done = 0;
  reg [BYTE_SIZE-1:0] rx_data = 0;
  reg [ADDRESS_SIZE-1:0] rd_addr = 0;

  // Observados
  wire mem_wr_en;
  wire [ADDRESS_SIZE-1:0] mem_wr_addr;
  wire [BUS_SIZE-1:0] mem_wr_data;
  wire [BUS_SIZE-1:0] instr;

  // Modelo de lo esperado y contadores
  reg [BUS_SIZE-1:0] expected [0:2**ADDRESS_SIZE-1];
  integer errors = 0;
  integer writes = 0;

  always #5 clock = ~clock;   // 100 MHz

  debug_unit #(
    .BUS_SIZE(BUS_SIZE), .ADDRESS_SIZE(ADDRESS_SIZE), .BYTE_SIZE(BYTE_SIZE)
  ) dut (
    .clock(clock), .reset(reset),
    .rx_done(rx_done), .rx_data(rx_data),
    .tx_start(), .tx_data(), .tx_done(1'b0),
    .mem_wr_en(mem_wr_en), .mem_wr_addr(mem_wr_addr), .mem_wr_data(mem_wr_data),
    .cpu_enable(),
    .pc({BUS_SIZE{1'b0}}), .if_id_instr({BUS_SIZE{1'b0}})
  );

  mem_programa #(
    .BUS_SIZE(BUS_SIZE), .ADDR_SIZE(ADDRESS_SIZE)
  ) mem (
    .clock(clock),
    .addr(rd_addr), .instr(instr),
    .wr_en(mem_wr_en), .wr_addr(mem_wr_addr), .wr_data(mem_wr_data)
  );

  // Cuenta las escrituras a memoria
  always @(posedge clock) if (mem_wr_en) writes = writes + 1;

  // Envía un byte como lo haría el RX: dato + rx_done, y luego una pausa
  task send_byte(input [7:0] b);
    begin
      @(negedge clock);
      rx_data = b;
      rx_done = 1;
      repeat (RX_DONE_CYCLES) @(negedge clock);
      rx_done = 0;
      repeat (GAP_CYCLES) @(negedge clock);
    end
  endtask

  // Envía una instrucción de 32 bits (byte más significativo primero)
  // y la guarda en el modelo de lo esperado
  task send_instr(input [ADDRESS_SIZE-1:0] pos, input [31:0] w);
    begin
      expected[pos] = w;
      send_byte(w[31:24]);
      send_byte(w[23:16]);
      send_byte(w[15:8]);
      send_byte(w[7:0]);
    end
  endtask

  // Lee una posición de la memoria y la compara con lo esperado
  task check_mem(input [ADDRESS_SIZE-1:0] pos);
    begin
      rd_addr = pos;
      #1;
      if (instr !== expected[pos]) begin
        errors = errors + 1;
        $display("[%0t] ERROR mem[%0d]: esperado %h, obtenido %h",
                 $time, pos, expected[pos], instr);
      end else
        $display("[%0t] ok    mem[%0d] = %h", $time, pos, instr);
    end
  endtask

  task check_writes(input integer esperado, input [255:0] nombre);
    begin
      if (writes !== esperado) begin
        errors = errors + 1;
        $display("ERROR %0s: escrituras = %0d, esperadas %0d", nombre, writes, esperado);
      end else
        $display("ok    %0s: %0d escrituras", nombre, writes);
    end
  endtask

  integer i;

  // Watchdog: corta si algo se cuelga
  initial begin
    #5_000_000;
    $display("TIMEOUT: la simulación no terminó");
    $finish;
  end

  initial begin
    for (i = 0; i < 2**ADDRESS_SIZE; i = i + 1) expected[i] = 32'hx;

    // Reset
    repeat (4) @(negedge clock);
    reset = 0;
    repeat (2) @(negedge clock);

    // ---- Caso 1: carga normal (2 instrucciones + HALT) ----
    $display("--- Caso 1: carga normal ---");
    send_byte(CMD_LOAD);
    send_instr(0, 32'h11223344);   // bytes distintos: se ve el orden
    send_instr(1, 32'h00A30293);   // addi x5, x6, 10
    send_instr(2, HALT);           // el HALT también se escribe
    repeat (5) @(negedge clock);
    check_writes(3, "caso 1");
    check_mem(0);
    check_mem(1);
    check_mem(2);
    if (dut.state !== 3'b000) begin
      errors = errors + 1;
      $display("ERROR: la FSM no volvió a IDLE tras el HALT");
    end

    // ---- Caso 2: byte desconocido en IDLE ----
    $display("--- Caso 2: byte desconocido en IDLE ---");
    send_byte(8'h5A);
    send_byte(8'h00);
    repeat (5) @(negedge clock);
    check_writes(3, "caso 2 (sin escrituras nuevas)");
    if (dut.state !== 3'b000) begin
      errors = errors + 1;
      $display("ERROR: la FSM salió de IDLE con un byte desconocido");
    end

    // ---- Caso 3: programa más corto; la dirección arranca en 0 ----
    $display("--- Caso 3: programa más corto, dirección arranca en 0 ---");
    send_byte(CMD_LOAD);
    send_instr(0, 32'hDEADBEEF);
    send_instr(1, HALT);
    repeat (5) @(negedge clock);
    check_writes(5, "caso 3");
    check_mem(0);
    check_mem(1);
    check_mem(2);   // conserva el HALT del programa anterior

    // ---- Caso 4: sin HALT, la dirección da la vuelta ----
    $display("--- Caso 4: sin HALT (256 instrucciones y 1 más) ---");
    send_byte(CMD_LOAD);
    for (i = 0; i < 2**ADDRESS_SIZE; i = i + 1)
      send_instr(i, 32'h00000013 + i);
    send_instr(0, 32'hCAFE0001);   // la 257ª pisa la posición 0
    repeat (5) @(negedge clock);
    check_writes(5 + 257, "caso 4");
    check_mem(0);
    check_mem(1);
    check_mem(255);
    if (dut.state !== 3'b001) begin
      errors = errors + 1;
      $display("ERROR: sin HALT la FSM debería seguir en LOAD");
    end

    if (errors == 0) $display("=== TODO OK ===");
    else             $display("=== %0d ERRORES ===", errors);
    $finish;
  end

endmodule
