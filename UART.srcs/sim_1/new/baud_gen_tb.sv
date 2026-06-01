`timescale 1ns / 1ps

module baud_gen_tb();

    logic clk;
    logic rst;
    logic baud_tick;

    baud_generator dut (
        .rst(rst),
        .clk(clk),
        .baud_tick(baud_tick)
    );

    initial begin
        clk = 0;
    end

    always begin
        #5 clk = ~clk;  // 100 MHz clock
    end

    initial begin
        rst = 1;
        #20
        rst = 0;
    end

    initial begin
        $monitor("time=%0t clk=%0b baud_tick=%0b cnt=%0d",
            $time, clk, baud_tick, dut.count);

        #1000000;
        $finish;
    end

endmodule
