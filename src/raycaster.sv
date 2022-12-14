`default_nettype none
`timescale 1ns / 1ps

import proctypes::*;

/// FPU:
// add_sub: 8
// compare: 2
// divide: 15
// multiply: 6
// sqrt: 15
// float_to_fixed: 5

// 206-Stage pipeline - currently supports only sphere
// TODO: add normal, support additional shapetype (change quadratic)
module raycaster#(
    parameter P1_STAGES = 58,
    parameter P2_STAGES = 30,
    parameter P3_STAGES = 53,
    parameter P4_STAGES = 14,
    parameter P5_STAGES = 51
)(
    input wire clk,
    input wire rst,
    input wire valid_in,
    input vec3 src,
    input vec3 dir,
    input wire ShapeAddr shape_addr_in,
    input wire ShapeType shape_type,
    input vec3 shape_trans_inv,
    input quaternion shape_rot,
    input vec3 shape_scale_inv,
    output logic valid_out,
    output ShapeAddr shape_addr_out,
    output logic hit,
    output float16 sq_distance,
    output vec3 intersection
);
    // pipeline shape_addr
    parameter TOTAL_STAGES = P1_STAGES + P2_STAGES + P3_STAGES + P4_STAGES + P5_STAGES;

    pipe #(
        .LENGTH(TOTAL_STAGES),
        .WIDTH(SHAPE_ADDR_WIDTH)
    ) pipe_addr_all (
        .clk(clk),
        .rst(rst),
        .in(shape_addr_in),
        .out(shape_addr_out)
    );
    
    pipe #(
        .LENGTH(TOTAL_STAGES),
        .WIDTH(1)
    ) pipe_valid_all (
        .clk(clk),
        .rst(rst),
        .in(valid_in),
        .out(valid_out)
    );

    /// Phase 1: Transform src + dir
    // 58-stage
    // src --[8]--> trans_src --[44]--> rot_trans_src --[6]--> scale_rot_trans_src
    // dir --[8]--> p1_s1_dir --[44]--> rot_dir       --[6]--> scale_rot_dir

    // Pipeline src, dir for later stages
    vec3 p1_src [P1_STAGES-1:0];
    vec3 p1_dir [P1_STAGES-1:0];
    vec3 p1_scale_inv [P1_STAGES-1:0];
    quaternion p1_rot [P1_STAGES-1:0];
    ShapeType p1_shape_type [P1_STAGES-1:0];

    always_ff @( posedge clk ) begin
        p1_src[0] <= src;
        p1_dir[0] <= dir;
        p1_rot[0] <= shape_rot;
        p1_scale_inv[0] <= shape_scale_inv;
        p1_shape_type[0] <= shape_type;
        for (int i = 1; i < P1_STAGES; i = i+1) begin
            p1_src[i] <= p1_src[i-1];
            p1_dir[i] <= p1_dir[i-1];
            p1_rot[i] <= p1_rot[i-1];
            p1_scale_inv[i] <= p1_scale_inv[i-1];
            p1_shape_type[i] <= p1_shape_type[i-1];
        end
    end

    // 8-stage
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

    // 44-stage
    vec3 rot_trans_src;
    logic rot_trans_src_valid;
    rotate_inv rinv_src(
        .clk(clk),
        .rst(rst),
        .valid_in(trans_src_valid),
        .in(trans_src),
        .rot_inv(p1_rot[8-1]),
        .valid_out(rot_trans_src_valid),
        .out(rot_trans_src)
    );

    // 6-stage
    vec3 scale_rot_trans_src;
    logic scale_rot_trans_src_valid;
    scale scl_src(
        .clk(clk),
        .rst(rst),
        .valid_in(rot_trans_src_valid),
        .in(rot_trans_src),
        .scale(p1_scale_inv[44+8-1]),
        .valid_out(scale_rot_trans_src_valid),
        .out(scale_rot_trans_src)
    );

    // 8-stage pipeline to match translate
    localparam P1_PS1_STAGES = 8;
    vec3 p1_ps1_dir [P1_PS1_STAGES-1:0];
    logic p1_ps1_dir_valid [P1_PS1_STAGES-1:0];

    always_ff @( posedge clk ) begin
        p1_ps1_dir[0] <= dir;
        p1_ps1_dir_valid[0] <= valid_in;
        for (int i = 1; i < P1_PS1_STAGES; i = i + 1) begin
            p1_ps1_dir[i]       <= p1_ps1_dir[i-1]; 
            p1_ps1_dir_valid[i] <= p1_ps1_dir_valid[i-1];
        end
    end

    // 44-stage
    vec3 rot_dir;
    logic rot_dir_valid;
    rotate_inv rinv_dir(
        .clk(clk),
        .rst(rst),
        .valid_in(p1_ps1_dir_valid[P1_PS1_STAGES-1]),
        .in(p1_ps1_dir[P1_PS1_STAGES-1]),
        .rot_inv(p1_rot[8-1]),
        .valid_out(rot_dir_valid),
        .out(rot_dir)
    );

    // 6-stage
    vec3 scale_rot_dir;
    logic scale_rot_dir_valid;
    scale scl_dir(
        .clk(clk),
        .rst(rst),
        .valid_in(rot_dir_valid),
        .in(rot_dir),
        .scale(p1_scale_inv[44+8-1]),
        .valid_out(scale_rot_dir_valid),
        .out(scale_rot_dir)
    );


    /// Phase 2: Generate conic quadratics
    //  30-stage

    // Pipeline src, dir for later stages
    vec3 p2_src [P2_STAGES-1:0];
    vec3 p2_dir [P2_STAGES-1:0];
    vec3 p2_src_transform [P2_STAGES-1:0];
    vec3 p2_dir_transform [P2_STAGES-1:0];
    quaternion p2_rot [P2_STAGES-1:0];
    ShapeType p2_shape_type [P2_STAGES-1:0];

    always_ff @( posedge clk ) begin
        p2_src[0] <= p1_src[P1_STAGES-1];
        p2_dir[0] <= p1_dir[P1_STAGES-1];

        p2_src_transform[0] <= scale_rot_trans_src;
        p2_dir_transform[0] <= scale_rot_dir;

        p2_rot[0] <= p1_rot[P1_STAGES-1];
        p2_shape_type[0] <= p1_shape_type[P1_STAGES-1];

        for (int i = 1; i < P2_STAGES; i = i+1) begin
            p2_src[i] <= p2_src[i-1];
            p2_dir[i] <= p2_dir[i-1];
            
            p2_src_transform[i] <= p2_src_transform[i-1];
            p2_dir_transform[i] <= p2_dir_transform[i-1];

            p2_rot[i] <= p2_rot[i-1];
            p2_shape_type[i] <= p2_shape_type[i-1];
        end
    end

    logic sphere_quad_valid;
    float16 sphere_quad_2a;
    float16 sphere_quad_b;
    float16 sphere_quad_2c;
    // 30-stage
    sphere_quadratic sphere_quad(
        .clk(clk),
        .rst(rst),
        .valid_in(scale_rot_trans_src_valid),
        .src(scale_rot_trans_src),
        .dir(scale_rot_dir),
        .shape_type(p1_shape_type[P1_STAGES-1]),
        .valid_out(sphere_quad_valid),
        .a2(sphere_quad_2a),
        .b(sphere_quad_b),
        .c2(sphere_quad_2c)
    ); 


    /// Phase 3: Solve quadratic
    // 53-stage

    // Pipeline src, dir for later stages
    vec3 p3_src [P3_STAGES-1:0];
    vec3 p3_dir [P3_STAGES-1:0];
    vec3 p3_src_transform [P3_STAGES-1:0];
    vec3 p3_dir_transform [P3_STAGES-1:0];
    quaternion p3_rot [P3_STAGES-1:0];
    ShapeType p3_shape_type [P3_STAGES-1:0];

    always_ff @( posedge clk ) begin
        p3_src[0] <= p2_src[P2_STAGES-1];
        p3_dir[0] <= p2_dir[P2_STAGES-1];

        p3_src_transform[0] <= p2_src_transform[P2_STAGES-1];
        p3_dir_transform[0] <= p2_dir_transform[P2_STAGES-1];

        p3_rot[0] <= p2_rot[P2_STAGES-1];
        p3_shape_type[0] <= p2_shape_type[P2_STAGES-1];

        for (int i = 1; i < P3_STAGES; i = i+1) begin
            p3_src[i] <= p3_src[i-1];
            p3_dir[i] <= p3_dir[i-1];
            
            p3_src_transform[i] <= p3_src_transform[i-1];
            p3_dir_transform[i] <= p3_dir_transform[i-1];

            p3_rot[i] <= p3_rot[i-1];
            p3_shape_type[i] <= p3_shape_type[i-1];
        end
    end

    // compute || dir ||^2
    float16 p3_dir_sq_mag;

    // 22-stages
    dot_product p3_dp_dot (
        .clk(clk),
        .rst(rst),
        .valid_in(1'b1),
        .a(p3_dir[P3_STAGES-22-1]),
        .b(p3_dir[P3_STAGES-22-1]),
        .valid_out(),
        .a_dot_b(p3_dir_sq_mag)
    );


    // 53-stage
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

    /// Phase 4: Intersection + distance
    // 14-stages
    // sq_distance = t * t * || dir ||^2 (2*6 = 12 stages + 2 pipelining)
    // intersection = src + t * dir (8+6 = 14 stages)
    // intersection_transform = src_transform + t * dir_transform (8+6 = 14 stages)

    // Pipeline stages for hit
    logic p4_hit [P4_STAGES-1:0];

    quaternion p4_rot [P4_STAGES-1:0];
    ShapeType p4_shape_type [P4_STAGES-1:0];

    always_ff @( posedge clk ) begin
        p4_hit[0] <= quad_sol_real_pos;

        p4_rot[0] <= p3_rot[P3_STAGES-1];
        p4_shape_type[0] <= p3_shape_type[P3_STAGES-1];

        for (int i = 1; i < P4_STAGES; i = i+1) begin
            p4_hit[i] <= p4_hit[i-1];

            p4_rot[i] <= p4_rot[i-1];
            p4_shape_type[i] <= p4_shape_type[i-1];
        end
    end
    
    // 6-stage
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

    // 6 pipeline stage
    localparam P4_PS1_STAGES = 6;
    float16 p4_s1_dir_sq_mag[P4_PS1_STAGES-1:0];
    always_ff @( posedge clk ) begin 
        p4_s1_dir_sq_mag[0] <= p3_dir_sq_mag;
        for (int i = 1; i < P4_PS1_STAGES; i = i+1) begin
            p4_s1_dir_sq_mag[i] <= p4_s1_dir_sq_mag[i-1];
        end
    end

    // 6-stages
    float16 p4_sq_distance;
    float_multiply p4_mult_sq_distance (
        .aclk(clk),                                  // input wire aclk
        .s_axis_a_tvalid(p4_t_sq_valid),            // input wire s_axis_a_tvalid
        .s_axis_a_tdata(p4_s1_dir_sq_mag[P4_PS1_STAGES-1]),              // input wire [15 : 0] s_axis_a_tdata
        .s_axis_b_tvalid(p4_t_sq_valid),            // input wire s_axis_b_tvalid
        .s_axis_b_tdata(p4_t_sq),              // input wire [15 : 0] s_axis_b_tdata
        // .m_axis_result_tvalid(p4_sq_distance_valid),  // output wire m_axis_result_tvalid
        .m_axis_result_tdata(p4_sq_distance)    // output wire [15 : 0] m_axis_result_tdata
    );

    localparam P4_PS3_STAGES = 2;
    float16 p4_ps3_sq_distance [P4_PS3_STAGES-1:0];
    always_ff @( posedge clk ) begin
        p4_ps3_sq_distance[0] <= p4_sq_distance;
        for (int i = 1; i < P4_PS3_STAGES; i = i+1) begin
            p4_ps3_sq_distance[i] <= p4_ps3_sq_distance[i-1];
        end
    end

    // compute intersection = src + t * dir (14 stages)
    vec3 p4_ps1_src [P4_PS1_STAGES];
    always_ff @( posedge clk ) begin 
        p4_ps1_src[0] <= p3_src[P3_STAGES-1];
        for (int i = 1; i < P4_PS1_STAGES; i = i + 1) begin
            p4_ps1_src[i] <= p4_ps1_src[i-1];
        end
    end

    vec3 p4_t_scale;
    assign p4_t_scale[0] = quad_sol;
    assign p4_t_scale[1] = quad_sol;
    assign p4_t_scale[2] = quad_sol;

    // intersection = src + t*dir
    // 6 stages
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

    // 8 stages
    logic p4_intersection_valid;
    vec3 p4_intersection;

    translate p4_add_t_dir_src (
        .clk(clk),
        .rst(rst),
        .valid_in(p4_dir_scaled_valid),
        .in(p4_dir_scaled),
        .trans(p4_ps1_src[P4_PS1_STAGES-1]),
        .valid_out(p4_intersection_valid),
        .out(p4_intersection)
    );

    
    // intersection_transform = src_transform + t*dir_transform
    // 6 stages
    vec3 p4_ps1_src_transform [P4_PS1_STAGES];
    always_ff @( posedge clk ) begin 
        p4_ps1_src_transform[0] <= p3_src_transform[P3_STAGES-1];
        for (int i = 1; i < P4_PS1_STAGES; i = i + 1) begin
            p4_ps1_src_transform[i] <= p4_ps1_src_transform[i-1];
        end
    end

    logic p4_dir_transform_scaled_valid;
    vec3 p4_dir_transform_scaled;

    scale p4_mult_t_dir_transform (
        .clk(clk),
        .rst(rst),
        .valid_in(quad_sol_valid),
        .in(p3_dir_transform[P3_STAGES-1]),
        .scale(p4_t_scale),
        .valid_out(p4_dir_transform_scaled_valid),
        .out(p4_dir_transform_scaled)
    );

    // 8 stages
    logic p4_intersection_transform_valid;
    vec3 p4_intersection_transform;

    translate p4_add_t_dir_src_transform (
        .clk(clk),
        .rst(rst),
        .valid_in(p4_dir_transform_scaled_valid),
        .in(p4_dir_transform_scaled),
        .trans(p4_ps1_src_transform[P4_PS1_STAGES-1]),
        .valid_out(p4_intersection_transform_valid),
        .out(p4_intersection_transform)
    );

    
    // TODO: normal computation
    /// Phase 5: normal computation
    // 51-stage
    // normal_transform = f(intersection transform) (combinational for conic sections) (1-stage)
    // normal = R  S^-1 normal_transform (44 + 6 = 50-stage)
    
    vec3 p1234_shape_scale_inv;
    generate
        genvar scale_pipe_i;
        for (scale_pipe_i = 0; scale_pipe_i < 3; scale_pipe_i = scale_pipe_i + 1) begin
            pipe#(
                .LENGTH(P1_STAGES + P2_STAGES + P3_STAGES + P4_STAGES),
                .WIDTH(16)
            ) pipe_scale (
                .clk(clk),
                .rst(rst),
                .in(shape_scale_inv[scale_pipe_i]),
                .out(p1234_shape_scale_inv[scale_pipe_i])
            );
        end
    endgenerate

    // 1-stage: decide normal_transform based on shape type
    vec3 p5_normal_transform;

    always_ff @( posedge clk ) begin
        case (p4_shape_type[P4_STAGES-1])
            stOff: begin
                p5_normal_transform[0] <= 0;
                p5_normal_transform[1] <= 0;
                p5_normal_transform[2] <= 0;
            end
            stSphere: begin
                p5_normal_transform[0] <= p4_intersection_transform[0];
                p5_normal_transform[1] <= p4_intersection_transform[1];
                p5_normal_transform[2] <= p4_intersection_transform[2];
            end
            stCylinder: begin
                p5_normal_transform[0] <= p4_intersection_transform[0];
                p5_normal_transform[1] <= p4_intersection_transform[1];
                p5_normal_transform[2] <= 0;
            end
            stCone: begin
                // NOT normalized!
                p5_normal_transform[0] <= p4_intersection_transform[0];
                p5_normal_transform[1] <= p4_intersection_transform[1];
                p5_normal_transform[2] <= {~p4_intersection_transform[2][15], p4_intersection_transform[2][14:0]};
            end
        endcase
    end

    // vec3 p5_scale_inv;
    // generate
    //     genvar p5_pipe_scale_inv_i;
    //     for (p5_pipe_scale_inv_i = 0; p5_pipe_scale_inv_i < 3; p5_pipe_scale_inv_i = p5_pipe_scale_inv_i+1) begin
    //         pipe#(
    //             .LENGTH(1),
    //             .WIDTH(16)
    //         ) pipe_p5_scale_inv (
    //             .clk(clk),
    //             .rst(rst),
    //             .in(p1234_shape_scale_inv[p5_pipe_scale_inv_i]),
    //             .out(p5_scale_inv[p5_pipe_scale_inv_i])
    //         )
    //     end
    // endgenerate

    // // Scale - 6 stages    
    // vec3 p5_scale_normal_transform;
    // // logic scale_normal_transform_valid;
    // scale scl_src(
    //     .clk(clk),
    //     .rst(rst),
    //     .valid_in(1'b1),
    //     .in(p5_normal_transform),
    //     .scale(p5_scale_inv),
    //     // .valid_out(scale_rot_trans_src_valid),
    //     .out(p5_scale_normal_transform)
    // );

    // generate
    // pipe#(
    //     .LENGTH(7),
    //     .WIDTH(64)
    // ) pipe_p5_rot (
    //     .clk(clk),
    //     .rst(rst),
    //     .in({p4_rot[P4_STAGES-1][0], p4_rot[P4_STAGES-1][1], p4_rot[P4_STAGES-1][2], p4_rot[P4_STAGES-1][3]}),

    // )

    // // rotate - 44-stages
    // rotate p5_rotate_normal (
    //     .clk(clk),
    //     .rst(rst),
    //     .valid_in(1'b1),
    //     .in()
    //     .rot(),

    // )

    logic p5_intersection_valid;
    pipe#(
        .LENGTH(P5_STAGES),
        .WIDTH(1)
    ) p5_pipe_intersection_valid (
        .clk(clk),
        .rst(rst),
        .in(p4_intersection_valid),
        .out(p5_intersection_valid)
    );

    logic p5_hit;
    pipe#(
        .LENGTH(P5_STAGES),
        .WIDTH(1)
    ) p5_pipe_hit (
        .clk(clk),
        .rst(rst),
        .in(p4_hit[P4_STAGES-1]),
        .out(p5_hit)
    );

    ShapeType p5_shape_type;
    pip#(
        .LENGTH(P5_STAGES),
        .WIDTH(4)
    ) p5_pipe_shape_type (
        .clk(clk),
        .rst(rst),
        .in(p4_shape_type[P4_STAGES-1]),
        .out(p5_shape_type)
    );

    float16 p5_sq_distance;
    pipe#(
        .LENGTH(P5_STAGES),
        .WIDTH(16)
    ) p5_pipe_sq_distance (
        .clk(clk),
        .rst(rst),
        .in(p4_ps3_sq_distance[P4_PS3_STAGES-1]),
        .out(p5_sq_distance)
    );

    vec3 p5_intersection;
    generate
        genvar p5_intersection_pipe_i;
        for (p5_intersection_pipe_i = 0; p5_intersection_pipe_i < 3; p5_intersection_pipe_i = p5_intersection_pipe_i + 1) begin
            pipe#(
                .LENGTH(P5_STAGES),
                .WIDTH(16)
            ) p5_pipe_sq_distance (
                .clk(clk),
                .rst(rst),
                .in(p4_intersection[p5_intersection_pipe_i]),
                .out(p5_intersection[p5_intersection_pipe_i])
            );
        end
    endgenerate



    // Distance should be scaled solution
    // assign valid_out = p5_intersection_valid;
    assign hit = p5_hit && (p5_shape_type != stOff);
    assign sq_distance = p5_sq_distance;

    assign intersection[0] = p5_intersection[0];
    assign intersection[1] = p5_intersection[1];
    assign intersection[2] = p5_intersection[2];
endmodule


// takes RAYCASTER_STAGES + NUM_SHAPES + O(1) cycles to produce result
// folded design
module all_shapes_raycaster (
    input wire clk,
    input wire rst,
    input wire valid_in,
    input vec3 src,
    input vec3 dir,
    input Shape cur_shape,
    output ShapeAddr read_shape_addr,
    output logic valid_out,
    output logic hit,
    output vec3 intersection,
    output Shape hit_shape,
    output logic[1:0] debug_state
);
    typedef enum logic[1:0] { IDLE, SENDING, WAITING, TABULATING } all_shape_rc_state;
    all_shape_rc_state state;
    assign debug_state = state;

    vec3 cur_src;
    vec3 cur_dir;

    ShapeAddr cur_shape_addr;
    assign read_shape_addr = cur_shape_addr;
    logic valid_final_shape;

    ShapeAddr cur_shape_addr_1;
    logic valid_shape_addr_1;
    logic valid_final_shape_1;
    
    ShapeAddr cur_shape_addr_2;
    logic valid_shape_addr_2;
    logic valid_final_shape_2;

    always_ff @( posedge clk ) begin 
        if (rst) begin
            state <= IDLE;
            cur_shape_addr <= 0;
            valid_final_shape <= 1'b0;
            valid_final_shape_1 <= 1'b0;
            valid_final_shape_2 <= 1'b0;
            valid_shape_addr_1 <= 1'b0;
            valid_shape_addr_2 <= 1'b0;
        end else begin
            if (state == IDLE && valid_in) begin
                state <= SENDING;
                cur_src <= src;
                cur_dir <= dir;
                cur_shape_addr <= 0;
                valid_shape_addr_1 <= 1'b0;
                valid_final_shape <= 1'b0;
            end else if (state == SENDING) begin
                if (cur_shape_addr == NUM_SHAPES - 1) begin
                    state <= WAITING;
                end else begin
                    cur_shape_addr <= cur_shape_addr + 1;
                end
                valid_shape_addr_1 <= 1'b1;
                valid_final_shape <= 1'b0;
            end else if (state == WAITING ) begin
                valid_shape_addr_1 <= 1'b0;
                if (p_raycast_valid[COMPARE_STAGES-1]) begin
                    if (p_raycast_shape_addr[COMPARE_STAGES-1] == NUM_SHAPES - 1) begin
                        state <= TABULATING;
                    end
                end
                valid_final_shape <= 1'b0;
            end else if (state == TABULATING) begin
                if (valid_final_shape_2) begin
                    state <= IDLE;
                end else if (!valid_final_shape && !valid_final_shape_1) begin
                    valid_final_shape <= 1'b1;
                    cur_shape_addr <= best_shape_addr;
                end else begin
                    valid_final_shape <= 1'b0;
                end
                valid_shape_addr_1 <= 1'b0;
            end else begin
                valid_final_shape <= 1'b0;
                valid_shape_addr_1 <= 1'b0;
            end

            cur_shape_addr_1 <= cur_shape_addr;
            cur_shape_addr_2 <= cur_shape_addr_1;
            valid_shape_addr_2 <= valid_shape_addr_1;

            valid_final_shape_1 <= valid_final_shape;
            valid_final_shape_2 <= valid_final_shape_1;
        end
    end

    vec3 shape_trans_inv;
    assign shape_trans_inv[0] = {~cur_shape.xloc[15], cur_shape.xloc[14:0]};
    assign shape_trans_inv[1] = {~cur_shape.yloc[15], cur_shape.yloc[14:0]};
    assign shape_trans_inv[2] = {~cur_shape.zloc[15], cur_shape.zloc[14:0]};

    quaternion shape_rot;
    assign shape_rot[0] = cur_shape.rrot;
    assign shape_rot[1] = cur_shape.irot;
    assign shape_rot[2] = cur_shape.jrot;
    assign shape_rot[3] = cur_shape.krot;

    vec3 shape_scale_inv;
    assign shape_scale_inv[0] = cur_shape.xscl;
    assign shape_scale_inv[1] = cur_shape.yscl;
    assign shape_scale_inv[2] = cur_shape.zscl;

    logic raycast_valid;
    ShapeAddr raycast_shape_addr;
    logic raycast_hit;
    float16 raycast_sq_distance;
    vec3 raycast_intersection;

    raycaster raycast (
        .clk(clk),
        .rst(rst),
        .valid_in(valid_shape_addr_2),
        .src(cur_src),
        .dir(cur_dir),
        .shape_addr_in(cur_shape_addr_2),
        .shape_type(cur_shape.sType),
        .shape_trans_inv(shape_trans_inv),
        .shape_rot(shape_rot),
        .shape_scale_inv(shape_scale_inv),
        .valid_out(raycast_valid),
        .shape_addr_out(raycast_shape_addr),
        .hit(raycast_hit),
        .sq_distance(raycast_sq_distance),
        .intersection(raycast_intersection)
    );


    // 2 stages for compare
    localparam COMPARE_STAGES = 2;
    logic p_raycast_valid [COMPARE_STAGES-1:0];
    ShapeAddr p_raycast_shape_addr [COMPARE_STAGES-1:0];
    logic p_raycast_hit [COMPARE_STAGES-1:0];
    float16 p_raycast_sq_distance [COMPARE_STAGES-1:0];
    vec3 p_raycast_intersection [COMPARE_STAGES-1:0];

    always_ff @( posedge clk ) begin 
        p_raycast_valid[0] <= raycast_valid;
        p_raycast_shape_addr[0] <= raycast_shape_addr;
        p_raycast_hit[0] <= raycast_hit;
        p_raycast_sq_distance[0] <= raycast_sq_distance;
        p_raycast_intersection[0] <= raycast_intersection;

        for (int i = 1; i < COMPARE_STAGES; i = i+1) begin
            p_raycast_valid[i] <= p_raycast_valid[i-1];
            p_raycast_shape_addr[i] <= p_raycast_shape_addr[i-1];
            p_raycast_hit[i] <= p_raycast_hit[i-1];
            p_raycast_sq_distance[i] <= p_raycast_sq_distance[i-1];
            p_raycast_intersection[i] <= p_raycast_intersection[i-1];
        end
    end

    logic [7:0] compare_result;
    float_compare compare_raycast_best (
        .aclk(clk),                                        // input wire aclk
        .s_axis_a_tvalid(raycast_valid),                  // input wire s_axis_a_tvalid
        .s_axis_a_tdata(raycast_sq_distance),                    // input wire [15 : 0] s_axis_a_tdata
        .s_axis_b_tvalid(raycast_valid),                  // input wire s_axis_b_tvalid
        .s_axis_b_tdata(best_sq_distance),                    // input wire [15 : 0] s_axis_b_tdata
        .s_axis_operation_tvalid(raycast_valid),  // input wire s_axis_operation_tvalid
        .s_axis_operation_tdata(fpuOpLt),    // input wire [7 : 0] s_axis_operation_tdata
        // .m_axis_result_tvalid(m_axis_result_tvalid),        // output wire m_axis_result_tvalid
        .m_axis_result_tdata(compare_result)          // output wire [7 : 0] m_axis_result_tdata
    );

    ShapeAddr best_shape_addr;
    logic best_valid;
    float16 best_sq_distance;
    vec3 best_intersection;


    always_ff @( posedge clk ) begin
        if (rst) begin
            best_valid <= 1'b0;
            best_sq_distance <= 0;
        end else begin
            if (state == IDLE && valid_in) begin
                best_valid <= 1'b0;
            end else if (state == SENDING || state == WAITING) begin
                if (p_raycast_hit[COMPARE_STAGES-1] && p_raycast_valid[COMPARE_STAGES-1]) begin
                    // received raycast result
                    if (!best_valid || compare_result[0]) begin
                        // if no best or if raycast dist < best, update best
                        best_valid <= 1'b1;
                        best_sq_distance <= p_raycast_sq_distance[COMPARE_STAGES-1];
                        best_shape_addr <= p_raycast_shape_addr[COMPARE_STAGES-1];
                        best_intersection <= p_raycast_intersection[COMPARE_STAGES-1];
                    end
                end
            end
        end
    end

    assign valid_out = valid_final_shape_2;
    assign hit = best_valid;
    // assign sq_distance = best_sq_distance;
    assign intersection = best_intersection;
    assign hit_shape = cur_shape;

endmodule

`default_nettype wire