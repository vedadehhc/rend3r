`default_nettype none
`timescale 1ns / 1ps

import proctypes::*;

module iprocessor (
    input wire clk_100mhz,
    input wire rst,
    output logic execInst_valid,
    output DecodedInst execInst,
    output logic mem_ready,
    output Camera cur_camera,
    output Light cur_light,
    output logic [GEOMETRY_WIDTH-1:0] cur_geo
);
    logic fetch_valid_out;
    InstructionAddr fetch_pc;
    Instruction fetch_inst;

    // TODO: pass back stall signals
    instruction_bank fetch (
        .clk(clk_100mhz),
        .rst(rst),
        .action(fetchDequeue),
        .instruction_valid(fetch_valid_out),
        .pc_out(fetch_pc),
        .inst(fetch_inst)
    );

    logic parse_valid_out;
    DecodedInst dInst;

    InstructionAddr decode_pc;
    parser decode (
        .clk(clk_100mhz),
        .rst(rst),
        .pc_in(fetch_pc),
        .instruction(fetch_inst),
        .valid_in(fetch_valid_out),
        .valid_out(parse_valid_out),
        .dInst(dInst),
        .pc_out(decode_pc)
    );

    // assign led[15:11] = dInst.prop;
    // assign led[8:3] = dInst.iType == opLightSet ? dInst.lIndex : dInst.sIndex[5:0];
    // assign led[2:0] = dInst.iType;

    execute exec (
        .clk_100mhz(clk_100mhz),
        .rst(rst),
        .dInst_valid_in(parse_valid_out),
        .dInst_in(dInst),
        .pc(decode_pc),
        .dInst_valid_out(execInst_valid),
        .dInst_out(execInst),
        .memory_ready(mem_ready),
        .cur_camera(cur_camera),
        .cur_light(cur_light),
        .cur_geo(cur_geo)
    );

endmodule;

`default_nettype wire