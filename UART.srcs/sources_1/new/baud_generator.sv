`timescale 1ns / 1ps

module baud_generator #(
        parameter BAUD = 9600
    )(
        input   logic rst,
        input   logic clk,
        output  logic baud_tick
    );
    
    localparam CLOCK = 100000000;
    localparam BAUD_CYCLES = CLOCK / BAUD;
    
    logic [$clog2(BAUD_CYCLES)-1:0] count;
    
    always_ff @(posedge clk) begin
        if (rst) begin
            count <= '0;
            baud_tick <= '0;
        end else begin
            if (count == (BAUD_CYCLES-1)) begin
                count <= '0;
                baud_tick <= 1'b1;
            end else begin
                count <= count + 1'b1;
                baud_tick <= '0;
            end
        end 
    end 
endmodule
