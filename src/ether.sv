`default_nettype none
`timescale 1ns / 1ps

module ether(
    input wire clk, 
    input wire rst,
    input wire [1:0] rxd,
    input wire crsdv,
    output logic axiov,
    output logic [1:0] axiod 
);

typedef enum {WAITING, FALSE_CARRIER, PREAMBLE, SFD1, SFD2, SFD3, SFD4, READING}  ether_state;

ether_state state;
logic [4:0] preamble_count;
logic received;

assign axiov = (state == READING) & crsdv;
assign axiod = axiov ? rxd : 2'b00;

always_ff @( posedge clk ) begin 
    if (rst) begin
        state <= WAITING;
        preamble_count <= 5'b0;
        received <= 1'b0;
    end else begin
        case (state)
            WAITING: begin
                if (crsdv == 1'b1 && rxd == 2'b01) begin
                    state <= PREAMBLE;
                    preamble_count <= 5'b01;
                end
            end
            FALSE_CARRIER: begin
                if (~crsdv) begin
                    state <= WAITING;
                    preamble_count <= 5'b0;
                end
            end
            PREAMBLE: begin
                if (rxd != 2'b01) begin
                    state <= FALSE_CARRIER;
                end else begin
                    preamble_count <= preamble_count + 1;
                    if (preamble_count == 5'd27) begin
                        state <= SFD1;
                    end
                end
            end
            SFD1: begin
                if (rxd == 2'b01) begin
                    state <= SFD2;
                end else begin
                    state <= FALSE_CARRIER;
                end
            end
            SFD2: begin
                if (rxd == 2'b01) begin
                    state <= SFD3; 
                end else begin
                    state <= FALSE_CARRIER;
                end
            end
            SFD3: begin
                if (rxd == 2'b01) begin
                    state <= SFD4; 
                end else begin
                    state <= FALSE_CARRIER;
                end
            end
            SFD4: begin
                if (rxd == 2'b11) begin
                    state <= READING; 
                end else begin
                    state <= FALSE_CARRIER;
                end
            end
            READING: begin
                if (~crsdv) begin
                    state <= WAITING;
                    received <= 1'b0;
                end else begin
                    received <= 1'b1;
                end
            end
            default: begin
                state <= WAITING;
            end
        endcase
    end
end

endmodule

`default_nettype wire
