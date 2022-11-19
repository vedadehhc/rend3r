`default_nettype none
`timescale 1ns / 1ps

module aggregate(
    input wire clk,
    input wire rst,
    input wire axiiv,
    input wire [1:0] axiid,
    output logic axiov,
    output logic [31:0] axiod
);
    typedef enum  { WAITING, RECEIVE_1, RECEIVE_2, RECEIVE} aggregate_state;
    aggregate_state state;
    aggregate_state prev_state;

    logic [63:0] data_buffer;
    logic [3:0] count;

    assign axiov = ((state == RECEIVE && prev_state == RECEIVE_2) && (count == 4'd0));
    assign axiod = data_buffer[63:32]; 

    always_ff @(posedge clk) begin
        prev_state <= state;
        if (rst) begin
            data_buffer <= 0;
            state <= WAITING;
        end else begin
            case (state) 
                WAITING: begin
                    if (axiiv) begin
                        data_buffer <= {62'b0, axiid};
                        count <= 4'd1;
                        state <= RECEIVE_1;
                    end
                end
                RECEIVE_1: begin
                    if (axiiv) begin
                        data_buffer <= {data_buffer[61:0], axiid};
                        if (count == 4'd15) begin
                            count <= 0;
                            state <= RECEIVE_2;
                        end else begin 
                            count <= count + 1;
                        end
                    end else begin
                        state <= WAITING;
                    end
                end
                RECEIVE_2: begin
                    if (axiiv) begin
                        data_buffer <= {data_buffer[61:0], axiid};
                        if (count == 4'd15) begin
                            count <= 0;
                            state <= RECEIVE;
                        end else begin 
                            count <= count + 1;
                        end
                    end else begin
                        state <= WAITING;
                    end
                end
                RECEIVE: begin
                    if (axiiv) begin
                        data_buffer <= {data_buffer[61:0], axiid};
                        if (count == 4'd15) begin
                            count <= 0;
                        end else begin 
                            count <= count + 1;
                        end
                    end else begin
                        state <= WAITING;
                    end
                end
            endcase
        end
    end

endmodule

`default_nettype wire