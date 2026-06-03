`timescale 1ns / 1ps

module uart_loopback_sim_tb();

    logic clk;
    logic rst;
    
    logic tx_start;
    logic [7:0] tx_data;
    logic tx_busy;
    
    logic [7:0] rx_data;
    logic rx_busy;

    uart_loopback_sim dut (
        .clk(clk),
        .rst(rst),

        .tx_start(tx_start),
        .tx_data(tx_data),

        .tx_busy(tx_busy),

        .rx_busy(rx_busy),
        .rx_data(rx_data)
    );
    
    initial begin
        clk = 0;
    end

    always begin
        #5 clk = ~clk;  // 100 MHz clock
    end

    task send_byte(input logic [7:0] data);
        wait(tx_busy == 0);

        @(posedge clk);
        tx_data = data;
        tx_start = 1;

        @(posedge clk);
        tx_start = 0;

    endtask
    
     task check_byte(input logic [7:0] expected);
        wait(rx_busy == 1'b1);
        wait(rx_busy == 1'b0);
        #1;

        if (rx_data !== expected) begin
            $fatal(1, "RX mismatch: got 0x%02h expected 0x%02h",
                rx_data, expected);
        end

        $display("PASS: received 0x%02h", rx_data);
        @(posedge clk);
    endtask

    initial begin
        rst = 1;
        tx_start = 0;
        tx_data = 8'h00;

        repeat (3) @(posedge clk);
        rst = 0;

        fork
            send_byte(8'h55);
            check_byte(8'h55);
            wait(tx_busy == 0);
        join

        fork
            send_byte(8'h30);
            check_byte(8'h30);
            wait(tx_busy == 0);
        join 
        
        fork
            send_byte(8'hFF);
            check_byte(8'hFF);
            wait(tx_busy == 0);
        join 
        
        repeat (5) @(posedge clk);
        $finish;
    end

    
endmodule
