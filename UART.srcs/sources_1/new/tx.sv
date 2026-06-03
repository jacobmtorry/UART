`timescale 1ns / 1ps

module tx(
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
    

    state_t cur_state;
    logic [2:0] count;
    logic [7:0] tx_reg;
    
    // FSM state updates on clock cycle
    always_ff @(posedge clk) begin
        if (rst) begin
            cur_state <= IDLE;
            tx_busy <= 1'b0;
            tx_serial <= 1'b1;
            count <= 3'b0;
        end else begin
            case(cur_state)
            
                IDLE: begin
                    tx_serial <= 1'b1;
                    tx_busy <= 1'b0;
                    if(tx_start) begin
                        tx_busy <= 1'b1;
                        tx_reg <= tx_data;
                        cur_state <= START;
                    end
                end
                
                START: begin 
                    tx_busy <= 1'b1;
                    if(baud_tick) begin 
                        tx_serial <= 1'b0;
                        count <= 3'b0;
                        cur_state <= DATA;
                    end
                end 
                
                DATA: begin 
                    tx_busy <= 1'b1;
                    if(baud_tick) begin 
                        tx_serial <= tx_reg[count];
                        if(count == 3'd7) begin 
                            cur_state <= STOP;
                        end else begin
                            count <= count + 1'b1;
                        end 
                    end
                end
                
                STOP: begin
                    tx_busy <= 1'b1;
                    if(baud_tick) begin
                        tx_serial <= 1'b1;
                        tx_busy <= 1'b0;
                        cur_state <= IDLE;
                    end
                end 
                
                default: cur_state <= IDLE;
            endcase 
        end
    end

endmodule
