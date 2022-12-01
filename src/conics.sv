`default_nettype none
`timescale 1ns / 1ps

import proctypes::*;

module sphere_quadratic(
    input wire clk,
    input wire rst,
    input wire valid_in,
    input vec3 src,
    input vec3 dir,
    output logic valid_out,
    output float16 a,
    output float16 b,
    output float16 c
);
    
endmodule

`default_nettype wire