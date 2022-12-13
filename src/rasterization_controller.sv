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
    output logic busy,
    output TriangleAddr cur_tri_addr,
    output logic next_triangle_valid,
    output Triangle next_triangle
);

    logic completed_frame;
    assign busy = !completed_frame;

    TriangleAddr cur_tri_addr_1;
    TriangleAddr cur_tri_addr_2;

    logic tri_valid_1;
    logic tri_valid_2;

    assign next_triangle = cur_triangle;
    assign next_triangle_valid = tri_valid_2;

    always_ff @( posedge clk ) begin 
        if (rst) begin
            cur_tri_addr <= 0;
            completed_frame <= 1'b1;
            tri_valid_1 <= 1'b0;
            tri_valid_2 <= 1'b0;
        end else begin
            if (execInst_valid && (execInst.iType == opFrame || execInst.iType == opRender)) begin
                if (execInst.iType == opFrame) begin
                    cur_tri_addr <= 0;
                    completed_frame <= 1'b0;
                    tri_valid_1 <= 1'b0;
                end else if (execInst.iType == opRender) begin
                    cur_tri_addr <= 0;
                    completed_frame <= 1'b1;
                    tri_valid_1 <= 1'b0;
                end
            end else if (!completed_frame && mem_ready) begin
                if (cur_tri_addr == NUM_TRIANGLES - 1) begin
                    completed_frame <= 1'b1;
                end
                cur_tri_addr <= cur_tri_addr + 1;
                tri_valid_1 <= 1'b1;
            end else begin
                tri_valid_1 <= 1'b0;
            end
            tri_valid_2 <= tri_valid_1;
            cur_tri_addr_1 <= cur_tri_addr;
            cur_tri_addr_2 <= cur_tri_addr_1;
        end
    end


endmodule

`default_nettype wire