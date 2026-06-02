`timescale 1ns / 1ps

module tx_tb();

    logic clk;
    logic rst;
    logic tx_start;
    logic [7:0] tx_data;
    logic tx_busy;
    logic tx_serial;

    UART_top dut (
        .rst(rst),
        .clk(clk),

        .tx_start(tx_start),
        .tx_data(tx_data),

        .tx_busy(tx_busy),
        .tx_serial(tx_serial)
    );

    initial begin
        clk = 0;
    end

    always begin
        #5 clk = ~clk;  // 100 MHz clock
    end

    task send_byte(input logic [7:0] data);
    begin
        wait(tx_busy == 0);

        @(posedge clk);
        tx_data = data;
        tx_start = 1;

        @(posedge clk);
        tx_start = 0;
    end
    endtask

    initial begin
        rst = 1;
        tx_start = 0;
        tx_data = 8'h00;

        repeat (3) @(posedge clk);
        rst = 0;

        send_byte(8'h55);
        wait(tx_busy == 0);

        send_byte(8'h30);
        wait(tx_busy == 0);

        repeat (5) @(posedge clk);
        $finish;
    end

    initial begin
        $monitor("time=%0t rst=%0b start=%0b busy=%0b serial=%0b baud_tick=%0b",
            $time,
            rst,
            tx_start,
            tx_busy,
            tx_serial,
            dut.baud_gen_tx.baud_tick
        );
    end

    initial begin
        #1000000;
        $fatal(1, "Timeout");
    end

endmodule