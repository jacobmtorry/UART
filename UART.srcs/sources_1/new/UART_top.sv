`timescale 1ns / 1ps

module UART_top(
        input logic rst,
        input logic clk,
        
        input logic tx_start,
        input logic [7:0] tx_data,
        
        output logic tx_busy,
        output logic tx_serial  
    );
    
    logic baud_tick;
    
    baud_generator #(.BAUD(9600)) baud_gen_tx (
        .rst(rst),
        .clk(clk),
        .baud_tick(baud_tick)
    );
    
    Tx tx (
        .rst(rst),
        .clk(clk),
        
        .baud_tick(baud_tick),
        .tx_start(tx_start),
        .tx_data(tx_data),
        
        .tx_busy(tx_busy),
        .tx_serial(tx_serial) 
    );
    
endmodule
