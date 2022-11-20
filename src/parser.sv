`default_nettype none
`timescale 1ns / 1ps

// not pipelined
module parser (
    input wire clk,
    input wire rst,
    input wire [31:0] instruction,
    input wire valid_in,
    output logic valid_out,
    output DecodedInst dInst
);
    
endmodule

`default_nettype wire
