`timescale 1ns / 1ps

module uart_echo( 
        input  logic clk,
        input  logic rst,

        input  logic pc_rx,  // data from PC_tx to FPGA_rx
        
        output logic uart_tx // data from FPGA_tx to PC_rx
    );
    
    
    logic baud_tick;
    
    logic rx_done;
    logic rx_busy;
    logic [7:0] rx_data;
    
    logic tx_start;
    logic tx_busy;
    logic [7:0] tx_data;
    
    always_ff @(posedge clk) begin 
        if(rst) begin
            tx_start <= 1'b0;
            tx_data <= 8'b0;
        end else begin 
            tx_start <= 1'b0;
            if(rx_done && !tx_busy) begin
                tx_data <= rx_data;
                tx_start <= 1'b1;
            end 
        end 
    end 
    
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
        .tx_serial(uart_tx) 
    );
    
    rx #(.BAUD(115200)) rx (
        .rst(rst),
        .clk(clk),
        
        .rx_serial(pc_rx),
        
        .rx_busy(rx_busy),
        .rx_done(rx_done),
        .rx_data(rx_data)
    );

endmodule
