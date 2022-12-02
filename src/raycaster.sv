`default_nettype none
`timescale 1ns / 1ps

import proctypes::*;

// k-Stage pipeline
// src -> trans_src -> rot_trans_src -> scale_rot_trans_src
// dir -> dir_2 -> rot_dir -> scale_rot_dir
module raycaster(
    input wire clk,
    input wire rst,
    input wire valid_in,
    input vec3 src,
    input vec3 dir,
    input wire ShapeType shape_type,
    input vec3 shape_trans_inv,
    input quaternion shape_rot,
    input vec3 shape_scale_inv,
    output logic valid_out,
    output logic hit,
    output float16 distance,
    output vec3 intersection,
    output vec3 normal
);
    vec3 trans_src;
    logic trans_src_valid;
    translate trans(
        .clk(clk),
        .rst(rst),
        .valid_in(valid_in),
        .in(src),
        .trans(shape_trans_inv),
        .valid_out(trans_src_valid),
        .out(trans_src)
    );

    vec3 rot_trans_src;
    logic rot_trans_src_valid;
    rotate_inv rinv(
        .clk(clk),
        .rst(rst),
        .valid_in(trans_src_valid),
        .in(trans_src),
        .rot_inv(shape_rot),
        .valid_out(rot_trans_src_valid),
        .out(rot_trans_src)
    );

    vec3 scale_rot_trans_src;
    logic scale_rot_trans_src_valid;
    scale scl(
        .clk(clk),
        .rst(rst),
        .valid_in(rot_trans_src_valid),
        .in(rot_trans_src),
        .scale(shape_scale_inv),
        .valid_out(scale_rot_trans_src_valid),
        .out(scale_rot_trans_src)
    );

    // Pipeline stage to match translate
    vec3 dir_2;
    logic dir_valid_2;
    always_ff @( posedge clk ) begin
        dir_2 <= dir;
        dir_valid_2 <= valid_in;
    end

    vec3 rot_dir;
    logic rot_dir_valid;
    rotate_inv rinv(
        .clk(clk),
        .rst(rst),
        .valid_in(dir_valid_2),
        .in(dir_2),
        .rot_inv(shape_rot),
        .valid_out(rot_dir_valid),
        .out(rot_dir)
    );

    vec3 scale_rot_dir;
    logic scale_rot_dir_valid;
    rotate_inv rinv(
        .clk(clk),
        .rst(rst),
        .valid_in(rot_dir_valid),
        .in(dir),
        .rot_inv(rot_dir),
        .valid_out(scale_rot_dir_valid),
        .out(scale_rot_dir)
    );


endmodule

`default_nettype wire