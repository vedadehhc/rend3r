`default_nettype none
`timescale 1ns / 1ps

import proctypes::*;

// k-Stage pipeline - currently supports only sphere
// TODO: add normal, support additional shapetype (change quadratic)
// TODO: fix all pipelining
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
    output float16 sq_distance,
    output vec3 intersection
);

    /// Phase 1: Transform src + dir
    // 8-stage
    // src -> trans_src -> rot_trans_src (6) -> scale_rot_trans_src
    // dir -> dir_2 -> rot_dir (6) -> scale_rot_dir

    // Pipeline src, dir for later stages
    parameter P1_STAGES = 8;
    vec3 p1_src [P1_STAGES-1:0];
    vec3 p1_dir [P1_STAGES-1:0];
    // TODO: pipeline rot, shape_type for normal + other computation
    // quaternion p1_rot [P1_STAGES-1:0];
    // ShapeType p1_shape_type [P1_STAGES-1:0];

    always_ff @( posedge clk ) begin
        p1_src[0] <= src;
        p1_dir[0] <= dir;
        for (int i = 1; i < P1_STAGES; i = i+1) begin
            p1_src[i] <= p1_src[i-1];
            p1_dir[i] <= p1_dir[i-1];
        end
    end

    vec3 trans_src;
    logic trans_src_valid;
    translate translate_src(
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
    rotate_inv rinv_src(
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
    scale scl_src(
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
    rotate_inv rinv_dir(
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
    scale scl_dir(
        .clk(clk),
        .rst(rst),
        .valid_in(rot_dir_valid),
        .in(rot_dir),
        .scale(shape_scale_inv),
        .valid_out(scale_rot_dir_valid),
        .out(scale_rot_dir)
    );


    /// Phase 2: Generate conic quadratics
    //  4-stage

    // Pipeline src, dir for later stages
    parameter P2_STAGES = 4;
    vec3 p2_src [P2_STAGES-1:0];
    vec3 p2_dir [P2_STAGES-1:0];

    always_ff @( posedge clk ) begin
        p2_src[0] <= p1_src[P1_STAGES-1];
        p2_dir[0] <= p1_dir[P1_STAGES-1];
        for (int i = 1; i < P2_STAGES; i = i+1) begin
            p2_src[i] <= p2_src[i-1];
            p2_dir[i] <= p2_dir[i-1];
        end
    end

    logic sphere_quad_valid;
    float16 sphere_quad_2a;
    float16 sphere_quad_b;
    float16 sphere_quad_2c;

    sphere_quadratic sphere_quad(
        .clk(clk),
        .rst(rst),
        .valid_in(scale_rot_trans_src_valid),
        .src(scale_rot_trans_src),
        .dir(scale_rot_dir),
        .valid_out(sphere_quad_valid),
        .a2(sphere_quad_2a),
        .b(sphere_quad_b),
        .c2(sphere_quad_2c)
    ); 


    /// Phase 3: Solve quadratic
    // 6-stage

    // Pipeline src, dir for later stages
    parameter P3_STAGES = 6;
    vec3 p3_src [P3_STAGES-1:0];
    vec3 p3_dir [P3_STAGES-1:0];

    always_ff @( posedge clk ) begin
        p3_src[0] <= p2_src[P2_STAGES-1];
        p3_dir[0] <= p2_dir[P2_STAGES-1];
        for (int i = 1; i < P3_STAGES; i = i+1) begin
            p3_src[i] <= p3_src[i-1];
            p3_dir[i] <= p3_dir[i-1];
        end
    end

    // compute || dir ||^2
    float16 p3_dir_sq_mag;

    // 3-stages
    dot_product p3_dp_dot (
        .clk(clk),
        .rst(rst),
        .valid_in(1'b1),
        .a(p2_dir[P3_STAGES-4]),
        .b(p2_dir[P3_STAGES-4]),
        .valid_out(),
        .a_dot_b(p3_dir_sq_mag)
    );


    // solve quadratic
    logic quad_sol_valid;
    logic quad_sol_real_pos;
    float16 quad_sol;

    quadratic_solver_smallest_positive quad_solver(
        .clk(clk),
        .rst(rst),
        .valid_in(sphere_quad_valid),
        .a2(sphere_quad_2a),
        .b(sphere_quad_b),
        .c2(sphere_quad_2c),
        .valid_out(quad_sol_valid),
        .real_pos_sol(quad_sol_real_pos),
        .sol(quad_sol)
    );

    /// Phase 4: Final computations
    // 2 stages
    // sq_distance = t * t * || dir ||^2 (2 stages)
    // intersection = src + t * dir (2 stages)

    // Pipeline stages for hit
    parameter P4_STAGES = 2;
    logic p4_hit [P4_STAGES-1:0];

    always_ff @( posedge clk ) begin
        p4_hit[0] <= quad_sol_real_pos;
        for (int i = 1; i < P4_STAGES; i = i+1) begin
            p4_hit[i] <= p4_hit[i-1];
        end
    end
    
    logic p4_t_sq_valid;
    float16 p4_t_sq;
    float_multiply p4_mult_t_t (
        .aclk(clk),                                  // input wire aclk
        .s_axis_a_tvalid(quad_sol_valid),            // input wire s_axis_a_tvalid
        .s_axis_a_tdata(quad_sol),              // input wire [15 : 0] s_axis_a_tdata
        .s_axis_b_tvalid(quad_sol_valid),            // input wire s_axis_b_tvalid
        .s_axis_b_tdata(quad_sol),              // input wire [15 : 0] s_axis_b_tdata
        .m_axis_result_tvalid(p4_t_sq_valid),  // output wire m_axis_result_tvalid
        .m_axis_result_tdata(p4_t_sq)    // output wire [15 : 0] m_axis_result_tdata
    );

    // Pipeline stage
    float16 p4_s1_dir_sq_mag;
    always_ff @( posedge clk ) begin 
        p4_s1_dir_sq_mag <= p3_dir_sq_mag;
    end

    logic p4_sq_distance_valid;
    float16 p4_sq_distance;
    float_multiply p4_mult_sq_distance (
        .aclk(clk),                                  // input wire aclk
        .s_axis_a_tvalid(p4_t_sq_valid),            // input wire s_axis_a_tvalid
        .s_axis_a_tdata(p4_s1_dir_sq_mag),              // input wire [15 : 0] s_axis_a_tdata
        .s_axis_b_tvalid(p4_t_sq_valid),            // input wire s_axis_b_tvalid
        .s_axis_b_tdata(p4_t_sq),              // input wire [15 : 0] s_axis_b_tdata
        .m_axis_result_tvalid(p4_sq_distance_valid),  // output wire m_axis_result_tvalid
        .m_axis_result_tdata(p4_sq_distance)    // output wire [15 : 0] m_axis_result_tdata
    );

    // compute intersection = src + t * dir (2 stages)
    vec3 p4_s1_src;
    always_ff @( posedge clk ) begin 
        p4_s1_src <= p3_src[P3_STAGES-1];
    end

    vec3 p4_t_scale;
    assign p4_t_scale[0] = quad_sol;
    assign p4_t_scale[1] = quad_sol;
    assign p4_t_scale[2] = quad_sol;

    logic p4_dir_scaled_valid;
    vec3 p4_dir_scaled;

    scale p4_mult_t_dir (
        .clk(clk),
        .rst(rst),
        .valid_in(quad_sol_valid),
        .in(p3_dir[P3_STAGES-1]),
        .scale(p4_t_scale),
        .valid_out(p4_dir_scaled_valid),
        .out(p4_dir_scaled)
    );

    logic p4_intersection_valid;
    vec3 p4_intersection;

    translate p4_add_t_dir_src (
        .clk(clk),
        .rst(rst),
        .valid_in(p4_dir_scaled_valid),
        .in(p4_dir_scaled),
        .trans(p4_s1_src),
        .valid_out(p4_intersection_valid),
        .out(p4_intersection)
    );

    
    // TODO: normal computation
    // intersection_transform = src_transform + t * dir_transform (2 stages)
    // normal_transform = f(intersection transform) (combinational for conic sections)
    // normal = R * normal_transform (we don't care about scaling)


    // Distance should be scaled solution
    assign valid_out = p4_intersection_valid;
    assign hit = p4_hit[P4_STAGES-1];
    assign sq_distance = p4_sq_distance;

    assign intersection[0] = p4_intersection[0];
    assign intersection[1] = p4_intersection[1];
    assign intersection[2] = p4_intersection[2];
endmodule

`default_nettype wire