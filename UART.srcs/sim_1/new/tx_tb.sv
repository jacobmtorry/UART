`timescale 1ns / 1ps

module tx_tb();

    logic clk;
    logic rst;
    logic tx_start;
    logic [7:0] tx_data;
    logic tx_busy;
    logic tx_serial;
    
    logic [9:0] expected_frame;
    int bit_num;

    tx_top dut (
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
        expected_frame = {1'b1, data, 1'b0};
        bit_num = 0;
        tx_start = 1;

        @(posedge clk);
        tx_start = 0;

        wait(bit_num == 10);
    end
    endtask

    initial begin
        rst = 1;
        tx_start = 0;
        tx_data = 8'h00;
        expected_frame = 10'b0;
        bit_num = 0;

        repeat (3) @(posedge clk);
        rst = 0;

        send_byte(8'h55);
        wait(tx_busy == 0);

        send_byte(8'h30);
        wait(tx_busy == 0);
        
        send_byte(8'hFF);
        wait(tx_busy == 0);

        repeat (5) @(posedge clk);
        $finish;
    end

    always @(posedge clk) begin
        if (dut.baud_gen_tx.baud_tick && tx_busy) begin
            #1;

            if (bit_num >= 10) begin
                $fatal(1, "Saw extra UART bit after expected frame");
            end

            if (tx_serial !== expected_frame[bit_num]) begin
                $fatal(1,
                    "Mismatch at bit %0d: got %0b expected %0b",
                    bit_num, tx_serial, expected_frame[bit_num]);
            end

            $display("Bit %0d Correct: %0b", bit_num, tx_serial);
            bit_num++;
        end 
    end

    initial begin
        //#1000000;
        //$fatal(1, "Timeout");
    end

endmodule
