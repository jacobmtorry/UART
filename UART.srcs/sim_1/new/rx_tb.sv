`timescale 1ns / 1ps

module rx_tb();

    localparam int BAUD_CYCLES = 100000000 / 9600;

    logic clk;
    logic rst;
    logic rx_serial;
    logic [7:0] rx_data;
    logic rx_busy;

    rx dut (
        .rst(rst),
        .clk(clk),
        .rx_serial(rx_serial),
        .rx_busy(rx_busy),
        .rx_data(rx_data)
    );

    initial begin
        clk = 0;
    end

    always begin
        #5 clk = ~clk;  // 100 MHz clock
    end

    task send_serial_byte(input logic [7:0] data);
        int i;
        rx_serial = 1'b0;  // start bit
        repeat (BAUD_CYCLES) @(posedge clk);

        for (i = 0; i < 8; i++) begin
            rx_serial = data[i];  // data bits, LSB first
            repeat (BAUD_CYCLES) @(posedge clk);
        end

        rx_serial = 1'b1;  // stop bit
        repeat (BAUD_CYCLES) @(posedge clk);
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
        rx_serial = 1'b1;

        repeat (3) @(posedge clk);
        rst = 0;

        repeat (3) @(posedge clk);

        fork
            send_serial_byte(8'h55);
            check_byte(8'h55);
        join

        fork
            send_serial_byte(8'h30);
            check_byte(8'h30);
        join

        fork
            send_serial_byte(8'hFF);
            check_byte(8'hFF);
        join

        repeat (10) @(posedge clk);
        $finish;
    end

    initial begin
//        #5000000;
//        $fatal(1, "Timeout");
    end

endmodule
