`default_nettype none
`timescale 1ns / 1ps

import proctypes::*;

module rt_controller_tb;
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
    iprocessor processor (
        .clk_100mhz(clk),
        .rst(rst),
        .light_read_addr(rt_light_addr),
        .geometry_read_addr(rt_shape_addr),
        .controller_busy(rt_busy),
        .execInst_valid(execInst_valid),
        .execInst(execInst),
        .mem_ready(mem_ready),
        .cur_camera(cur_camera),
        .cur_light(cur_light),
        .cur_geo(cur_geo)
    );

    // rasterization controller 
    // should iterate through all triangles and pass to rasterizer
    logic rt_busy;
    ShapeAddr rt_shape_addr;
    LightAddr rt_light_addr;

    // logic rast_tri_valid;
    // Triangle rast_tri;

    raytracing_controller controller (
        .clk(clk),
        .rst(rst),
        .execInst_valid(execInst_valid),
        .execInst(execInst),
        .mem_ready(mem_ready),
        .cur_shape(cur_geo),
        .cur_light(cur_light),
        .cur_camera(cur_camera),
        .busy(rt_busy),
        .cur_shape_addr(rt_shape_addr),
        .cur_light_addr(rt_light_addr)
    );

    
    
    initial begin
        $dumpfile("controller.vcd");
        $dumpvars(0, rt_controller_tb);
        $display("Starting Sim");

        clk = 1'b0;
        rst = 1'b0;
        #10;
        #30;
        rst = 1'b1;
        #10;
        rst = 1'b0;
        #80000;


        $display("\nFinishing Sim");
        $finish;
    end
endmodule

`default_nettype wire