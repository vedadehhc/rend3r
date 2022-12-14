`default_nettype none
`timescale 1ns / 1ps

import proctypes::*;

// takes (RAYCASTER_STAGES + NUM_SHAPES + O(1)) * (NUM_LIGHTS + 1) * NUM_PIXELS + O(1) cycles 
// TODO: add lighting
module raytracing_controller(
    input wire clk,
    input wire rst,
    input wire execInst_valid,
    input wire DecodedInst execInst,
    input wire mem_ready,
    input Shape cur_shape,
    input Light cur_light,
    input Camera cur_camera,
    output logic busy,
    output ShapeAddr cur_shape_addr,
    output LightAddr cur_light_addr,
    output logic valid_out,
    output ScreenX pixel_x_out,
    output ScreenY pixel_y_out,
    output logic[15:0] pixel_value
);
// camera at origin, pointing in negative z

    typedef enum { WAITING, INITIAL, LIGHTING, GIVE_OUTPUT, GEN_NEXT_PIXEL } raytrace_state;
    raytrace_state state;
    logic sent_command;
    assign busy = (state != WAITING);
    assign valid_out = state == GIVE_OUTPUT;
    assign pixel_x_out = pixel_x;
    assign pixel_y_out = pixel_y;
    
    // send all raycasts for single pixel (all initial, then NUM_LIGHTS sets of lighting)
    // pipeline shape along with raycast

    vec3 light_dir;
    assign light_dir[0] = {~cur_light.xfor[15], cur_light.xfor[14:0]};
    assign light_dir[1] = {~cur_light.yfor[15], cur_light.yfor[14:0]};
    assign light_dir[2] = {~cur_light.zfor[15], cur_light.zfor[14:0]};

    logic valid_light_1;
    logic valid_light_2;

    ScreenX pixel_x;
    ScreenY pixel_y;

    vec3 camera_dir;
    vec3 camera_src; 
    // assume camera at (0,0,0)
    assign camera_src[0] = cur_camera.xloc;
    assign camera_src[1] = cur_camera.yloc;
    assign camera_src[2] = cur_camera.zloc;


    always_ff @( posedge clk ) begin 
        if (rst) begin
            state <= WAITING;
            pixel_x <= 0;
            pixel_y <= 0;
            sent_command <= 1'b0;
            pixel_value <= 0;
        end else begin
            if (execInst_valid && (execInst.iType == opFrame || execInst.iType == opRender)) begin
                if (execInst.iType == opFrame) begin
                    state <= INITIAL;
                    pixel_x <= 0;
                    pixel_y <= 0;
                    sent_command <= 1'b0;
                    // assume camera faces (0, 0, -1)
                    camera_dir[0] <= CAMERA_TOP_LEFT_DIR_X;
                    camera_dir[1] <= CAMERA_TOP_LEFT_DIR_Y;
                    camera_dir[2] <= CAMERA_TOP_LEFT_DIR_Z;
                end else if (execInst.iType == opRender) begin
                    state <= WAITING;
                end
                shape_cast_valid_in <= 1'b0;
            end else if (busy && mem_ready) begin
                if (state == GEN_NEXT_PIXEL) begin
                    shape_cast_valid_in <= 1'b0;

                    if (pixel_x == SCREEN_WIDTH - 1 && pixel_y == SCREEN_HEIGHT - 1) begin
                        state <= WAITING;
                    end else if (pixel_x == SCREEN_WIDTH - 1 && valid_inc_ray_y) begin
                        pixel_x <= 0;
                        pixel_y <= pixel_y + 1;
                        camera_dir[0] <= CAMERA_TOP_LEFT_DIR_X;
                        camera_dir[1] <= inc_ray_y;
                        state <= INITIAL;
                    end else if (valid_inc_ray_x) begin
                        pixel_x <= pixel_x + 1;
                        camera_dir[0] <= inc_ray_x;
                        state <= INITIAL;
                    end else begin
                        state <= GEN_NEXT_PIXEL;
                    end
                end else if (state == INITIAL) begin
                    if (!sent_command) begin
                        sent_command <= 1'b1;
                        shape_cast_valid_in <= 1'b1;
                    end else begin
                        if (shape_cast_valid_out) begin
                            state <= GIVE_OUTPUT;
                            pixel_value <= shape_cast_hit ? shape_cast_hit_shape.col : 16'b0;
                        end
                        shape_cast_valid_in <= 1'b0;
                    end
                end else if (state == LIGHTING) begin
                    if (valid_light_2 && !sent_command) begin
                        sent_command <= 1'b1;
                        shape_cast_valid_in <= 1'b1;
                    end else begin
                        shape_cast_valid_in <= 1'b0;
                    end
                end else if (state == GIVE_OUTPUT) begin
                    shape_cast_valid_in <= 1'b0;
                    state <= GEN_NEXT_PIXEL;
                end
            end else begin
                shape_cast_valid_in <= 1'b0;
            end
        end
    end

    logic valid_inc_ray_x;
    float16 inc_ray_x;

    float_add_sub add_ray_x (
        .aclk(clk),                                        // input wire aclk
        .s_axis_a_tvalid(state == GEN_NEXT_PIXEL),                  // input wire s_axis_a_tvalid
        .s_axis_a_tdata(camera_dir[0]),                    // input wire [15 : 0] s_axis_a_tdata
        .s_axis_b_tvalid(1'b1),                  // input wire s_axis_b_tvalid
        .s_axis_b_tdata(CAMERA_PIXEL_SIZE),                    // input wire [15 : 0] s_axis_b_tdata
        .s_axis_operation_tvalid(1'b1),  // input wire s_axis_operation_tvalid
        .s_axis_operation_tdata(fpuOpAdd),    // input wire [7 : 0] s_axis_operation_tdata
        .m_axis_result_tvalid(valid_inc_ray_x),        // output wire m_axis_result_tvalid
        .m_axis_result_tdata(inc_ray_x)          // output wire [15 : 0] m_axis_result_tdata
    );

    logic valid_inc_ray_y;
    float16 inc_ray_y;

    float_add_sub add_ray_y (
        .aclk(clk),                                        // input wire aclk
        .s_axis_a_tvalid(state == GEN_NEXT_PIXEL),                  // input wire s_axis_a_tvalid
        .s_axis_a_tdata(camera_dir[1]),                    // input wire [15 : 0] s_axis_a_tdata
        .s_axis_b_tvalid(1'b1),                  // input wire s_axis_b_tvalid
        .s_axis_b_tdata(CAMERA_PIXEL_SIZE),                    // input wire [15 : 0] s_axis_b_tdata
        .s_axis_operation_tvalid(1'b1),  // input wire s_axis_operation_tvalid
        .s_axis_operation_tdata(fpuOpAdd),    // input wire [7 : 0] s_axis_operation_tdata
        .m_axis_result_tvalid(valid_inc_ray_y),        // output wire m_axis_result_tvalid
        .m_axis_result_tdata(inc_ray_y)          // output wire [15 : 0] m_axis_result_tdata
    );


    logic shape_cast_valid_in;
    logic shape_cast_valid_out;
    logic shape_cast_hit;
    vec3 shape_cast_intersection;
    Shape shape_cast_hit_shape;


    // calculate raycast direction based on pixel values
    // pass src, dir, shape type, shape transform to the raycaster

    all_shapes_raycaster shape_cast (
        .clk(clk),
        .rst(rst),
        .valid_in(shape_cast_valid_in),
        .src(camera_src),
        .dir(camera_dir),
        .cur_shape(cur_shape),
        .read_shape_addr(cur_shape_addr),
        .valid_out(shape_cast_valid_out),
        .hit(shape_cast_hit),
        .intersection(),
        .hit_shape(shape_cast_hit_shape)
    );

endmodule

`default_nettype wire