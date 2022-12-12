`default_nettype none
`timescale 1ns / 1ps

import proctypes::*;

module raytracing_controller(
    input wire clk,
    input wire rst,
    input wire execInst_valid,
    input wire DecodedInst execInst,
    input wire mem_ready,
    input Shape cur_shape,
    input Light cur_light,
    output logic busy,
    
);

endmodule

`default_nettype wire