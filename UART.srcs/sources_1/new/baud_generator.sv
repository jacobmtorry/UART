`timescale 1ns / 1ps

// We are using a 100MHz Clock

module baud_generator(
        input   logic rst,
        input   logic clk,
        output  logic baud_tick
    );
    
    logic [$clog2(868)-1:0] cnt;
    
    always_ff @(posedge clk) begin
        if (rst) begin
            cnt <= '0;
            baud_tick <= '0;
        end else begin
            if (cnt == 867) begin
                cnt <= '0;
                baud_tick <= 1'b1;
            end else begin
                cnt <= cnt + 1'b1;
                baud_tick <= '0;
            end
        end 
    end 
endmodule
