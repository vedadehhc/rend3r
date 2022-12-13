`default_nettype none
`timescale 1ns / 1ps

import proctypes::*;

module execute_tb;
    logic clk_100mhz;
    logic clk_50mhz;


    // 100 MHz clock
    always begin
        #5;
        clk_100mhz = !clk_100mhz;
    end
    // 50 MHz clock
    always begin
        #10;
        clk_50mhz = !clk_50mhz;
    end

    logic rst;
    logic dInst_valid;
    DecodedInst dInst;
    logic [NUM_INSTRUCTIONS_WIDTH-1:0] pc;

    logic memory_ready;
    Camera cur_camera;
    Light cur_light;
    Triangle cur_tri;

    execute exec (
        .clk_50mhz(clk_50mhz),
        .clk_100mhz(clk_100mhz),
        .rst(rst),
        .dInst_valid(dInst_valid),
        .dInst(dInst),
        .pc(pc),
        .light_read_addr({(LIGHT_ADDR_WIDTH){1'b0}}),
        .geometry_read_addr({(GEOMETRY_ADDR_WIDTH){1'b0}}),
        .memory_ready(memory_ready),
        .cur_camera(cur_camera),
        .cur_light(cur_light),
        .cur_geo(cur_tri)
    );

    initial begin
        $dumpfile("execute.vcd");
        $dumpvars(0, execute_tb);
        $display("Starting Sim");

        clk_50mhz = 1'b0;
        clk_100mhz = 1'b0;
        rst = 1'b0;
        dInst = {(DECODED_INSTRUCTION_WIDTH){1'b0}};
        dInst_valid = 1'b0;

        #20;
        rst = 1'b1;
        #20;
        rst = 1'b0;
        #20;
        #20;
        pc = {(NUM_INSTRUCTIONS_WIDTH){1'b0}};
        dInst.iType = opRender;
        dInst_valid = 1'b1;
        $display("Memory ready: \t\t%16b", memory_ready);
        $display("Cur camera xloc: \t%16b", cur_camera.xloc);
        $display("Cur camera yloc: \t%16b", cur_camera.yloc);
        $display("Cur camera zloc: \t%16b", cur_camera.zloc);
        #20;
        pc = pc + 1;
        dInst_valid = 1'b1;
        dInst.iType = opCameraSet;
        dInst.prop = cpXLocation;
        dInst.data = 16'b1010_1010_1010_1010;
        $display("Memory ready: \t\t%16b", memory_ready);
        $display("Cur camera xloc: \t%16b", cur_camera.xloc);
        $display("Cur camera yloc: \t%16b", cur_camera.yloc);
        $display("Cur camera zloc: \t%16b", cur_camera.zloc);
        #20;
        pc = pc + 1;
        dInst.iType = opFrame;
        dInst_valid = 1'b1;
        $display("Memory ready: \t\t%16b", memory_ready);
        $display("Cur camera xloc: \t%16b", cur_camera.xloc);
        $display("Cur camera yloc: \t%16b", cur_camera.yloc);
        $display("Cur camera zloc: \t%16b", cur_camera.zloc);
        #20;
        dInst.iType = opUnsupported;
        dInst_valid = 1'b0;
        $display("Memory ready: \t\t%16b", memory_ready);
        $display("Cur camera xloc: \t%16b", cur_camera.xloc);
        $display("Cur camera yloc: \t%16b", cur_camera.yloc);
        $display("Cur camera zloc: \t%16b", cur_camera.zloc);
        #20;
        $display("Memory ready: \t\t%16b", memory_ready);
        $display("Cur camera xloc: \t%16b", cur_camera.xloc);
        $display("Cur camera yloc: \t%16b", cur_camera.yloc);
        $display("Cur camera zloc: \t%16b", cur_camera.zloc);
        #20;
        $display("Memory ready: \t\t%16b", memory_ready);
        $display("Cur camera xloc: \t%16b", cur_camera.xloc);
        $display("Cur camera yloc: \t%16b", cur_camera.yloc);
        $display("Cur camera zloc: \t%16b", cur_camera.zloc);
        #20;
        $display("Memory ready: \t\t%16b", memory_ready);
        $display("Cur camera xloc: \t%16b", cur_camera.xloc);
        $display("Cur camera yloc: \t%16b", cur_camera.yloc);
        $display("Cur camera zloc: \t%16b", cur_camera.zloc);
        #20;
        pc = pc + 1;
        dInst.iType = opFrame;
        dInst_valid = 1'b1;
        $display("Memory ready: \t\t%16b", memory_ready);
        $display("Cur camera xloc: \t%16b", cur_camera.xloc);
        $display("Cur camera yloc: \t%16b", cur_camera.yloc);
        $display("Cur camera zloc: \t%16b", cur_camera.zloc);
        #20;
        pc = pc + 1;
        dInst_valid = 1'b1;
        dInst.iType = opCameraSet;
        dInst.prop = cpXLocation;
        dInst.data = 16'h0ff0;
        $display("Memory ready: \t\t%16b", memory_ready);
        $display("Cur camera xloc: \t%16b", cur_camera.xloc);
        $display("Cur camera yloc: \t%16b", cur_camera.yloc);
        $display("Cur camera zloc: \t%16b", cur_camera.zloc);
        #20;
        dInst_valid = 1'b0;
        $display("Memory ready: \t\t%16b", memory_ready);
        $display("Cur camera xloc: \t%16b", cur_camera.xloc);
        $display("Cur camera yloc: \t%16b", cur_camera.yloc);
        $display("Cur camera zloc: \t%16b", cur_camera.zloc);
        #20;
        dInst_valid = 1'b0;
        $display("Memory ready: \t\t%16b", memory_ready);
        $display("Cur camera xloc: \t%16b", cur_camera.xloc);
        $display("Cur camera yloc: \t%16b", cur_camera.yloc);
        $display("Cur camera zloc: \t%16b", cur_camera.zloc);
        #20;
        dInst_valid = 1'b0;
        $display("Memory ready: \t\t%16b", memory_ready);
        $display("Cur camera xloc: \t%16b", cur_camera.xloc);
        $display("Cur camera yloc: \t%16b", cur_camera.yloc);
        $display("Cur camera zloc: \t%16b", cur_camera.zloc);
        #20;
        dInst_valid = 1'b0;
        $display("Memory ready: \t\t%16b", memory_ready);
        $display("Cur camera xloc: \t%16b", cur_camera.xloc);
        $display("Cur camera yloc: \t%16b", cur_camera.yloc);
        $display("Cur camera zloc: \t%16b", cur_camera.zloc);
        #20;
        pc = pc + 1;
        dInst.iType = opFrame;
        dInst_valid = 1'b1;
        $display("Memory ready: \t\t%16b", memory_ready);
        $display("Cur camera xloc: \t%16b", cur_camera.xloc);
        $display("Cur camera yloc: \t%16b", cur_camera.yloc);
        $display("Cur camera zloc: \t%16b", cur_camera.zloc);
        #20;
        dInst_valid = 1'b0;
        $display("Memory ready: \t\t%16b", memory_ready);
        $display("Cur camera xloc: \t%16b", cur_camera.xloc);
        $display("Cur camera yloc: \t%16b", cur_camera.yloc);
        $display("Cur camera zloc: \t%16b", cur_camera.zloc);
        #20;
        pc = pc + 1;
        dInst_valid = 1'b1;
        dInst.iType = opCameraSet;
        dInst.prop = cpYLocation;
        dInst.data = 16'h00ff;
        $display("Memory ready: \t\t%16b", memory_ready);
        $display("Cur camera xloc: \t%16b", cur_camera.xloc);
        $display("Cur camera yloc: \t%16b", cur_camera.yloc);
        $display("Cur camera zloc: \t%16b", cur_camera.zloc);
        #20;
        dInst_valid = 1'b0;
        $display("Memory ready: \t\t%16b", memory_ready);
        $display("Cur camera xloc: \t%16b", cur_camera.xloc);
        $display("Cur camera yloc: \t%16b", cur_camera.yloc);
        $display("Cur camera zloc: \t%16b", cur_camera.zloc);
        #20;
        pc = pc + 1;
        dInst.iType = opFrame;
        dInst_valid = 1'b1;
        $display("Memory ready: \t\t%16b", memory_ready);
        $display("Cur camera xloc: \t%16b", cur_camera.xloc);
        $display("Cur camera yloc: \t%16b", cur_camera.yloc);
        $display("Cur camera zloc: \t%16b", cur_camera.zloc);
        #20;
        dInst_valid = 1'b0;
        $display("Memory ready: \t\t%16b", memory_ready);
        $display("Cur camera xloc: \t%16b", cur_camera.xloc);
        $display("Cur camera yloc: \t%16b", cur_camera.yloc);
        $display("Cur camera zloc: \t%16b", cur_camera.zloc);
        #20;
        dInst_valid = 1'b0;
        $display("Memory ready: \t\t%16b", memory_ready);
        $display("Cur camera xloc: \t%16b", cur_camera.xloc);
        $display("Cur camera yloc: \t%16b", cur_camera.yloc);
        $display("Cur camera zloc: \t%16b", cur_camera.zloc);
        #20;
        dInst_valid = 1'b0;
        $display("Memory ready: \t\t%16b", memory_ready);
        $display("Cur camera xloc: \t%16b", cur_camera.xloc);
        $display("Cur camera yloc: \t%16b", cur_camera.yloc);
        $display("Cur camera zloc: \t%16b", cur_camera.zloc);
        #20;

        #20;
        $display("\nFinishing Sim");
        $finish;
    end
endmodule

`default_nettype wire