`timescale 1ns / 1ps

module uart_loopback_sim( 
        input  logic clk,
        input  logic rst,

        input  logic tx_start,
        input  logic [7:0] tx_data,

        output logic tx_busy,

        output logic rx_busy,
        output logic [7:0] rx_data
    );
    
    
    logic baud_tick;
    logic serial_wire;
    
    baud_generator #(.BAUD(115200)) baud_gen_tx (
        .rst(rst),
        .clk(clk),
        .baud_tick(baud_tick)
    );
    
    tx tx (
        .rst(rst),
        .clk(clk),
        
        .baud_tick(baud_tick),
        .tx_start(tx_start),
        .tx_data(tx_data),
        
        .tx_busy(tx_busy),
        .tx_serial(serial_wire) 
    );
    
    rx #(.BAUD(115200)) rx (
        .rst(rst),
        .clk(clk),
        
        .rx_serial(serial_wire),
        
        .rx_busy(rx_busy),
        .rx_data(rx_data)
    );
    
    
endmodule
