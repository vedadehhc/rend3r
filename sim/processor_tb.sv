`default_nettype none
`timescale 1ns / 1ps

import proctypes::*;

module processor_tb;
    logic clk;
    logic rst;
    
    // 100 MHz clock
    always begin
        #5;
        clk = !clk;
    end

    logic execInst_valid;
    DecodedInst execInst;
    logic mem_ready;
    Camera cur_camera;
    Light cur_light;
    logic [GEOMETRY_WIDTH-1:0] cur_geo;
    iprocessor proc (
        .clk_100mhz(clk),
        .rst(rst),
        .execInst_valid(execInst_valid),
        .execInst(execInst),
        .mem_ready(mem_ready),
        .cur_camera(cur_camera),
        .cur_light(cur_light),
        .cur_geo(cur_geo)
    );

    
    initial begin
        $dumpfile("processor.vcd");
        $dumpvars(0, processor_tb);
        $display("Starting Sim");

        clk = 1'b0;
        rst = 1'b0;
        #10;
        #30;
        rst = 1'b1;
        #10;
        rst = 1'b0;
        #800;


        $display("\nFinishing Sim");
        $finish;
    end
endmodule

`default_nettype wire
