`default_nettype none
`timescale 1ns / 1ps

module firewall(
    input wire clk,
    input wire rst,
    input wire axiiv,
    input wire [1:0] axiid,
    output logic axiov,
    output logic [1:0] axiod
);
    parameter MAC_ADDRESS = 48'h69_69_5A_06_54_91;
    parameter BROADCAST = 48'hFF_FF_FF_FF_FF_FF;

    typedef enum {WAITING, READING_DEST, READING_BROADCAST, READING_SRC, VALID_DEST, INVALID_DEST}  firewall_state;
    firewall_state state;

    logic [47:0] mac_buffer;
    logic [4:0] count;

    assign axiod = axiid;
    assign axiov = (state == VALID_DEST) & axiiv;

    always_ff @( posedge clk ) begin 
        if (rst) begin
            state <= WAITING;
            mac_buffer <= MAC_ADDRESS;
            count <= 0;
        end else begin
            case (state)
                WAITING: begin
                    if (axiiv) begin
                        if (axiid == MAC_ADDRESS[47:46]) begin
                            state <= READING_DEST;
                            mac_buffer <= {MAC_ADDRESS[45:0], 2'b00};
                            count <= 1;
                        end else if (axiid == 2'b11) begin
                            state <= READING_BROADCAST;
                            count <= 1;
                        end else begin
                            state <= INVALID_DEST;
                        end
                    end
                end
                READING_DEST: begin
                    if (axiiv) begin
                        if (axiid == mac_buffer[47:46]) begin
                            mac_buffer <= {mac_buffer[45:0], 2'b00};
                            if (count == 5'd23) begin
                                count <= 0;
                                state <= READING_SRC;
                            end else begin
                                count <= count + 1;
                            end
                        end else begin
                            state <= INVALID_DEST;
                        end
                    end else begin
                        state <= WAITING;
                    end
                end
                READING_BROADCAST: begin
                    if (axiiv) begin
                        if (axiid == 2'b11) begin
                            if (count == 5'd23) begin
                                count <= 0;
                                state <= READING_SRC;
                            end else begin
                                count <= count + 1;
                            end
                        end else begin
                            state <= INVALID_DEST;
                        end
                    end else begin
                        state <= WAITING;
                    end
                end
                READING_SRC: begin
                    if (axiiv) begin
                        if (count == 5'd31) begin
                            count <= 0;
                            state <= VALID_DEST;
                        end else begin
                            count <= count+1;
                        end
                    end else begin
                        state <= WAITING;
                    end
                end
                VALID_DEST: begin
                    if (~axiiv) begin
                        state <= WAITING;
                    end
                end
                INVALID_DEST: begin
                    if (~axiiv) begin
                        state <= WAITING;
                    end
                end
            endcase
        end
    end

endmodule

`default_nettype wire
