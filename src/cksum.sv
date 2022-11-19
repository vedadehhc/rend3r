`default_nettype none
`timescale 1ns / 1ps

module cksum(
    input wire clk,
    input wire rst,
    input wire axiiv,
    input wire [1:0] axiid,
    output logic done,
    output logic kill
);

    logic crc_rst;
    assign crc_rst = rst || (old_axiiv & ~axiiv); // TODO: reset between frames

    logic crc_axiov;
    logic [31:0] crc_axiod;

    crc32 crc(
        .clk(clk),
        .rst(crc_rst),
        .axiiv(axiiv),
        .axiid(axiid),
        .axiov(crc_axiov),
        .axiod(crc_axiod)
    );

    logic old_axiiv;

    always_ff @( posedge clk ) begin 
        if (rst) begin
            old_axiiv <= 1'b0;
            done <= 1'b0;
            kill <= 1'b0;
        end else begin
            old_axiiv <= axiiv;
            if (old_axiiv & ~axiiv) begin
                if (crc_axiov) begin
                    done <= 1'b1;
                    kill <= (crc_axiod != 32'h38_fb_22_84);
                end
            end else if (~old_axiiv & axiiv) begin
                done <= 1'b0;
                kill <= 1'b0;
            end
        end
    end

endmodule

`default_nettype wire
