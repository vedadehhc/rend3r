`default_nettype none
`timescale 1ns / 1ps


module bitorder(
    input wire clk,
    input wire rst,
    input wire axiiv,
    input wire [1:0] axiid,
    output logic axiov,
    output logic [1:0] axiod
);
    typedef enum {WAITING, W0, W0R1, W1R0, R0, R1}  bitorder_state;

    bitorder_state state;
    logic [1:0] ind;
    logic [7:0] buffer0;
    logic [7:0] buffer1;

    assign axiov = (state == W0R1) || (state == W1R0) || (state == R0) || (state == R1);
    assign axiod = (state == W0R1 || state == R1) ? buffer1[7:6] : buffer0[7:6];

    always_ff @( posedge clk) begin
        if (rst) begin
            buffer0 <= 8'b0;
            buffer1 <= 8'b0;
            ind <= 2'd0;
            state <= WAITING;
        end else begin
            if (state == WAITING) begin
                if (axiiv) begin
                    state <= W0;
                    ind <= 1'b1;
                    buffer0[7:6] <= axiid; 
                end
            end else begin
                if (state == R0 || state == W1R0) begin
                    buffer0 <= {buffer0[5:0], 2'b00};
                end else begin
                    buffer1 <= {buffer1[5:0], 2'b00};
                end

                if (axiiv) begin
                    if (state == W0 || state == W0R1) begin
                        buffer0 <= {axiid, buffer0[7:2]};
                        if (ind == 2'd3) begin
                            // end of writing into 0
                            state <= W1R0;
                            ind <= 2'd0;
                        end else begin
                            ind <= ind + 1;
                        end
                    end else if (state == W1R0) begin
                        buffer1 <= {axiid, buffer1[7:2]};
                        if (ind == 2'd3) begin
                            // end of writing into 1
                            state <= W0R1;
                            ind <= 2'd0;
                        end else begin
                            ind <= ind + 1;
                        end
                    end
                end else begin
                    if (state == W0) begin
                        state <= WAITING;
                        buffer0 <= 8'b0;
                        buffer1 <= 8'b0;
                        ind <= 2'b0;
                    end else begin
                        if (ind == 2'd3) begin
                            // reading about to end
                            state <= WAITING;
                            buffer0 <= 8'b0;
                            buffer1 <= 8'b0;
                            ind <= 2'b0;
                        end else begin
                            // continue reading
                            ind <= ind + 1;
                            // move to pure read state if necessary
                            if (state == W0R1) begin
                                state <= R1;
                            end else if (state == W1R0) begin
                                state <= R0;
                            end
                        end
                    end
                end
            end
        end
    end
endmodule

`default_nettype wire
