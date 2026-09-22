`timescale 1ns / 1ps

module top
    # (
        parameter BUS_SIZE = 8,
        parameter OP_SIZE = 6
    )
    (
    input wire clock,
    input wire reset,
    input wire rx,
    output wire tx
    );
    
    wire [BUS_SIZE - 1: 0] d_in, d_out, r_data, w_data;
    wire tick, rx_done, tx_start, tx_done, rd;
    wire wr, tx_full, rx_empty;
    
    baud_rate #(
        .ciclos(325),
        .N(9)
    ) my_baud_rate (
        .clock(clock),
        .reset(reset),
        .tick(tick)
    );
    
    rx_uart #(
        .ticks(16),
        .bits(8)
    ) my_rx_uart (
        .clock(clock),
        .reset(reset),
        .rx(rx),
        .sample_tick(tick),
        .rx_done(rx_done),
        .dout(d_out)
    );
    
    tx_uart #(
        .BUS_SIZE(BUS_SIZE)
    ) my_tx_uart (
        .clock(clock),
        .reset(reset),
        .tx_start(tx_start),
        .d_in(d_in),
        .tx(tx),
        .tx_done(tx_done),
        .sample_tick(tick)
    );
    
    interfaz #(
        .BUS_SIZE(BUS_SIZE)
    ) my_interfaz (
        .clock(clock),
        .reset(reset),
        .d_out(d_out),
        .rx_done(rx_done),
        .tx_done(tx_done),
        .rd(rd),
        .w_data(w_data),
        .wr(wr),
        .r_data(r_data),
        .rx_empty(rx_empty),
        .d_in(d_in),
        .tx_start(tx_start),
        .tx_full(tx_full)
    );
    
    top_alu #(
        .BUS_SIZE(BUS_SIZE),
        .OP_SIZE(OP_SIZE)
    ) my_top_alu (
        .clock(clock),
        .reset(reset),
        .rdata(r_data),
        .rx_empty(rx_empty),
        .tx_full(tx_full),
        .rd(rd),
        .w_data(w_data),
        .wr(wr)
    );
    
endmodule
