`default_nettype none
`timescale 1ns / 1ps

import proctypes::*;

module parser_tb;
    logic clk;
    logic rst;
    logic [31:0] instruction;
    logic valid_in;

    logic valid_out;
    DecodedInst dInst;
    InstructionAddr pc;

    parser ip(
        .clk(clk),
        .rst(rst),
        .stall(1'b0),
        .pc_in(pc),
        .instruction(instruction),
        .valid_in(valid_in),
        .valid_out(valid_out),
        .dInst(dInst)
    );

    
    // 100 MHz clock
    always begin
        #5;
        clk = !clk;
    end

    initial begin
        $dumpfile("parser.vcd");
        $dumpvars(0, parser_tb);
        $display("Starting Sim");

        clk = 1'b0;
        rst = 1'b0;
        valid_in = 1'b0;
        #10;
        #10;
        rst = 1'b1;
        #10;
        rst = 1'b0;
        #10;
        #10;

        // TC1 : New render
        instruction = 32'b0000_0000_0000_0000_0000_0000_0000_0000;
        valid_in = 1'b1;
        #10;
        $display("-----------------------------");
        $display("Instruction type: \t %19b", dInst.iType);
        $display("Light index: \t\t %19b", dInst.lIndex);
        $display("Shape index:\t\t %19b", dInst.sIndex);
        $display("Shape type: \t\t %19b", dInst.sType);
        $display("Property 1: \t\t %19b", dInst.prop);
        $display("Property 2: \t\t %19b", dInst.prop2);
        $display("Data 1: \t\t %19b", dInst.data);
        $display("Data 2: \t\t %19b", dInst.data2);
        #10;
        // TC2: New frame
        instruction = 32'b0000_0000_0000_0000_0000_0010_0000_0000;
        valid_in = 1'b1;
        $display("-----------------------------");
        $display("Instruction type: \t %19b", dInst.iType);
        $display("Light index: \t\t %19b", dInst.lIndex);
        $display("Shape index:\t\t %19b", dInst.sIndex);
        $display("Shape type: \t\t %19b", dInst.sType);
        $display("Property 1: \t\t %19b", dInst.prop);
        $display("Property 2: \t\t %19b", dInst.prop2);
        $display("Data 1: \t\t %19b", dInst.data);
        $display("Data 2: \t\t %19b", dInst.data2);
        #10;
        $display("-----------------------------");
        $display("Instruction type: \t %19b", dInst.iType);
        $display("Light index: \t\t %19b", dInst.lIndex);
        $display("Shape index:\t\t %19b", dInst.sIndex);
        $display("Shape type: \t\t %19b", dInst.sType);
        $display("Property 1: \t\t %19b", dInst.prop);
        $display("Property 2: \t\t %19b", dInst.prop2);
        $display("Data 1: \t\t %19b", dInst.data);
        $display("Data 2: \t\t %19b", dInst.data2);
        #10;
        // TC3: Camera set x-location to 16'b0101_0101_0101_1111
        instruction = 32'b0101_0101_0101_1111_00001_00000000_001;
        valid_in = 1'b1;
        $display("-----------------------------");
        $display("Instruction type: \t %19b", dInst.iType);
        $display("Light index: \t\t %19b", dInst.lIndex);
        $display("Shape index:\t\t %19b", dInst.sIndex);
        $display("Shape type: \t\t %19b", dInst.sType);
        $display("Property 1: \t\t %19b", dInst.prop);
        $display("Property 2: \t\t %19b", dInst.prop2);
        $display("Data 1: \t\t %19b", dInst.data);
        $display("Data 2: \t\t %19b", dInst.data2);
        #10;
        $display("-----------------------------");
        $display("Instruction type: \t %19b", dInst.iType);
        $display("Light index: \t\t %19b", dInst.lIndex);
        $display("Shape index:\t\t %19b", dInst.sIndex);
        $display("Shape type: \t\t %19b", dInst.sType);
        $display("Property 1: \t\t %19b", dInst.prop);
        $display("Property 2: \t\t %19b", dInst.prop2);
        $display("Data 1: \t\t %19b", dInst.data);
        $display("Data 2: \t\t %19b", dInst.data2);
        #10;
        $display("-----------------------------");
        $display("Instruction type: \t %19b", dInst.iType);
        $display("Light index: \t\t %19b", dInst.lIndex);
        $display("Shape index:\t\t %19b", dInst.sIndex);
        $display("Shape type: \t\t %19b", dInst.sType);
        $display("Property 1: \t\t %19b", dInst.prop);
        $display("Property 2: \t\t %19b", dInst.prop2);
        $display("Data 1: \t\t %19b", dInst.data);
        $display("Data 2: \t\t %19b", dInst.data2);

        #10;
        $display("\nFinishing Sim");
        $finish;
    end
endmodule

`default_nettype wire