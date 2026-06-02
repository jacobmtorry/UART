`timescale 1ns / 1ps

module Tx(
        input logic rst,
        input logic clk,
        
        input logic baud_tick,
        input logic tx_start,
        input logic [7:0] tx_data,
        
        output logic tx_busy,
        output logic tx_serial     
    );
    
    // State definitions
    typedef enum logic [1:0] {
        IDLE    = 2'b00,
        START   = 2'b01,
        DATA    = 2'b10,
        STOP    = 2'b11
    } state_t;
    
    typedef enum logic [3:0] {
        BIT0 = 4'b0000,
        BIT1 = 4'b0001,
        BIT2 = 4'b0010,
        BIT3 = 4'b0011,
        BIT4 = 4'b0100,
        BIT5 = 4'b0101,
        BIT6 = 4'b0110,
        BIT7 = 4'b0111,
        BEEF = 4'b1111
    } bit_t;
    
    bit_t cur_bit, next_bit;
    state_t cur_state, next_state;
    
    // FSM state updates on clock cycle
    always_ff @(posedge clk) begin
        if (rst) begin
            cur_bit <= BIT0;
            cur_state <= IDLE;
        end else begin
            cur_bit <= next_bit;
            cur_state <= next_state;
        end
    end
    
    // Next state and output logic
    always_comb begin 
    
        next_state = cur_state;
        next_bit = cur_bit;
    
        case(cur_state)
        
            IDLE: begin
                if(tx_start) begin
                    tx_busy = 1'b1;
                    next_state = START;
                end
            end 
            
            START: begin
                if(baud_tick) begin
                    tx_serial = 1'b0; // This is the active low start bit
                    next_state = DATA;
                    next_bit = BIT0;
                end
            end
        
            DATA: begin
                case(cur_bit)
                    BIT0: begin
                        if(baud_tick) begin
                            tx_serial = tx_data[0];
                            next_bit = BIT1;
                        end
                    end
                    BIT1: begin
                        if(baud_tick) begin
                            tx_serial = tx_data[1];
                            next_bit = BIT2;
                        end
                    end
                    BIT2: begin
                        if(baud_tick) begin
                            tx_serial = tx_data[2];
                            next_bit = BIT3;
                        end
                    end
                    BIT3: begin
                        if(baud_tick) begin 
                            tx_serial = tx_data[3];
                            next_bit = BIT4;
                        end
                    end
                    BIT4: begin
                        if(baud_tick) begin
                            tx_serial = tx_data[4];
                            next_bit = BIT5;
                        end
                    end
                    BIT5: begin
                        if(baud_tick) begin
                            tx_serial = tx_data[5];
                            next_bit = BIT6;
                        end
                    end
                    BIT6: begin
                        if(baud_tick) begin
                            tx_serial = tx_data[6];
                            next_bit = BIT7;
                        end
                    end
                    BIT7: begin
                        if(baud_tick) begin
                            tx_serial = tx_data[7];
                            next_bit = BEEF;
                            next_state = STOP;
                        end
                    end
                endcase
            end
            
            STOP: begin
                if(baud_tick) begin
                    tx_serial = 1'b1;
                    tx_busy = 1'b0;
                    next_state = IDLE;
                end
            end
            default: begin
                tx_serial = 1'b1;
                tx_busy = 1'b0;
            end
        endcase 
    end
endmodule
