`default_nettype none
`timescale 1ns / 1ps

import proctypes::*;

module iprocessor (
    input wire clk_100mhz,
    input wire rst,
    input wire step_mode,
    input wire next_step,
    input wire LightAddr light_read_addr,
    input wire GeometryAddr geometry_read_addr,
    input wire controller_busy,
    output logic execInst_valid,
    output DecodedInst execInst,
    output logic mem_ready,
    output Camera cur_camera,
    output Light cur_light,
    output logic [GEOMETRY_WIDTH-1:0] cur_geo,
    output InstructionAddr pc_debug
);
    logic fetch_valid_out;
    InstructionAddr fetch_pc;
    Instruction fetch_inst;

    instruction_bank fetch (
        .clk(clk_100mhz),
        .rst(rst),
        .action(stall == 1'b1 ? fetchStall : fetchDequeue),
        .dIType(dInst.iType),
        .instruction_valid(fetch_valid_out),
        .pc_out(fetch_pc),
        .inst(fetch_inst)
    );

    logic parse_valid_out;
    DecodedInst dInst;

    InstructionAddr decode_pc;
    assign pc_debug = decode_pc;
    
    parser decode (
        .clk(clk_100mhz),
        .rst(rst),
        .stall(stall),
        .pc_in(fetch_pc),
        .instruction(fetch_inst),
        .valid_in(fetch_valid_out),
        .valid_out(parse_valid_out),
        .dInst(dInst),
        .pc_out(decode_pc)
    );

    logic exec_stall;
    logic stall;
    assign stall = exec_stall || (step_mode && !next_step);

    execute exec (
        .clk_100mhz(clk_100mhz),
        .rst(rst),
        .dInst_valid_in(parse_valid_out),
        .dInst_in(dInst),
        .pc(decode_pc),
        .controller_busy(controller_busy),
        .light_read_addr(light_read_addr),
        .geometry_read_addr(geometry_read_addr),
        .stall(exec_stall),
        .dInst_valid_out(execInst_valid),
        .dInst_out(execInst),
        .memory_ready(mem_ready),
        .cur_camera(cur_camera),
        .cur_light(cur_light),
        .cur_geo(cur_geo)
    );

endmodule;

`default_nettype wire