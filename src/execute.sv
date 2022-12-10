`default_nettype none
`timescale 1ns / 1ps

import proctypes::*;

module execute (
    input wire clk_100mhz,
    input wire rst,
    input wire dInst_valid_in,
    input wire DecodedInst dInst_in,
    input wire InstructionAddr pc,
    input wire [LIGHT_ADDR_WIDTH-1:0] light_read_addr,
    input wire [GEOMETRY_ADDR_WIDTH-1:0] geometry_read_addr,
    output logic dInst_valid_out,
    output DecodedInst dInst_out,
    output logic memory_ready,
    output Camera cur_camera,
    output Light cur_light,
    output logic [GEOMETRY_WIDTH-1:0] cur_geo
);

    logic [DECODED_INSTRUCTION_WIDTH + NUM_INSTRUCTIONS_WIDTH-1:0] dInst_flat;
    assign dInst_flat = {dInst_in, pc};


    // memory bank - handles writes due to instructions and gives latency 2 reads to camera, light, geo
    memory_bank mem_bank (
        .clk_100mhz(clk_100mhz),
        .rst(rst),
        .dInst_valid(dInst_valid_in),
        .dInst_flat(dInst_flat),
        .light_read_addr(light_read_addr),
        .geometry_read_addr(geometry_read_addr),
        .dInst_valid_out(dInst_valid_out),
        .dInst_out(dInst_out),
        .output_enabled(memory_ready),
        .camera_output(cur_camera),
        .light_output(cur_light),
        .geometry_output(cur_geo)
    );
endmodule

`default_nettype wire