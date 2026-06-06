`timescale 1ns / 1ps

module uart_loopback_fpga( 
        input  logic clk,
        input  logic rst,

        input  logic start,

        output logic RGB0_red,
        output logic RGB0_green
    );
    
    
    logic baud_tick;
    logic serial_wire;
    
    logic rx_done;
    logic rx_busy;
    logic [7:0] rx_data;
    
    logic tx_start;
    logic tx_busy;
    logic [7:0] tx_data;
    
    assign tx_start = start;
    
    always_ff @(posedge clk) begin 
        if(rst) begin
            RGB0_red <= 1'b0;
            RGB0_green <= 1'b0;
            tx_data <= 8'h55; // Hardcoded data to send
        end else begin 
            if(rx_done) begin
                if (rx_data == 8'h55) begin
                    RGB0_red <= 1'b0;
                    RGB0_green <= 1'b1;
                end else begin 
                    RGB0_red <= 1'b1;
                    RGB0_green <= 1'b0;
                end
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
        .tx_serial(serial_wire) 
    );
    
    rx #(.BAUD(115200)) rx (
        .rst(rst),
        .clk(clk),
        
        .rx_serial(serial_wire),
        
        .rx_busy(rx_busy),
        .rx_done(rx_done),
        .rx_data(rx_data)
    );

endmodule
