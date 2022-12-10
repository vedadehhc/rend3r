`default_nettype none
`timescale 1ns / 1ps

import proctypes::*;

module rasterization_controller(
    input wire clk,
    input wire rst,
    input wire execInst_valid,
    input wire DecodedInst execInst,
    input wire mem_ready,
    input Triangle cur_triangle,
    output logic stall,
    output TriangleAddr next_triangle_addr,
    output Triangle next_triangle
);
    TriangleAddr cur_tri_addr;
    logic completed_frame;

    always_ff @( posedge clk ) begin 
        if (rst) begin
            cur_tri_addr <= 0;
            completed_frame <= 1'b0;
        end else begin
            if (mem_ready) begin
                
            end
        end
    end

endmodule

`default_nettype wire