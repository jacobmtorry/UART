`timescale 1ns / 1ps

module rx #(
        parameter BAUD = 9600
    )(
        input logic rst,
        input logic clk,
        
        input logic rx_serial,
        
        output logic rx_busy,
        output logic rx_done,
        output logic [7:0] rx_data
    );
    
    localparam CLOCK = 100000000;
    localparam BAUD_CYCLES = CLOCK / BAUD;
    localparam SAMP_CYCLES = BAUD_CYCLES >> 1; // BAUD_CYCLES / 2
    
    logic [2:0] index;
    logic [7:0] rx_reg; 
    logic [$clog2(BAUD_CYCLES)-1:0] baud_count;
    logic [$clog2(SAMP_CYCLES)-1:0] internal_count;
    
    typedef enum logic [1:0] {
        IDLE    = 2'b00,
        START   = 2'b01,
        DATA    = 2'b10,
        STOP    = 2'b11
    } state_t;
    
    state_t state;
    
    always_ff  @(posedge clk) begin 
        if(rst) begin
            state <= IDLE;
            index <= 3'b0;
            rx_reg <= '0;
            rx_busy <= 1'b0;
            rx_data <= 8'b0;
            rx_done <= 1'b0;
            baud_count <= '0;
            internal_count <= '0;
        end else begin 
            case(state)
            
                IDLE: begin
                    rx_done <= 1'b0;
                    if(rx_serial == 0) begin
                        state <= START;
                        internal_count <= '0;
                    end 
                end 
                
                START: begin 
                    baud_count <= '0;
                    if(internal_count == (SAMP_CYCLES-1)) begin 
                        if(rx_serial == 1'b0) begin
                            state <= DATA;
                            rx_busy <= 1'b1;
                        end else begin
                            state <= IDLE;
                        end
                    end else begin
                        internal_count <= internal_count + 1'b1;
                    end 
                end
                
                DATA: begin 
                    if(baud_count == (BAUD_CYCLES-1)) begin
                        baud_count <= '0;
                        rx_reg[index] <= rx_serial;
                        if(index == 3'd7) begin 
                            state <= STOP;
                            index <= '0;
                        end else begin 
                            index <= index + 1'b1;
                        end 
                    end else begin 
                        baud_count <= baud_count + 1'b1;
                    end 
                end 
                
                STOP: begin 
                    if(baud_count == (BAUD_CYCLES-1)) begin
                        baud_count <= '0;
                        rx_busy <= 1'b0;
                        rx_data <= rx_reg;
                        rx_done <= 1'b1;
                        state <= IDLE;
                    end else begin
                        baud_count <= baud_count + 1'b1;
                    end 
                end 
                
                default: state <= IDLE; 
            endcase 
        end 
    end 
endmodule
