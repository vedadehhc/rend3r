`default_nettype none
`timescale 1ns / 1ps

import proctypes::*;

// 71-stage
module lighting(
    input wire clk,
    input wire rst,
    input wire valid_in,
    input vec3 normal,
    input vec3 dir,
    input wire [15:0] pixel_in,
    output logic valid_out,
    output logic[15:0] pixel_out
);

    // P1: 22-stage
    // n . n
    // d . d
    // n . d
    localparam P1_STAGES = 22;

    float16 n_dot_n;
    dot_product dp_n_n (
        .clk(clk),
        .rst(rst),
        .valid_in(1'b1),
        .a(normal),
        .b(normal),
        .a_dot_b(n_dot_n)
    );
    
    float16 d_dot_d;
    dot_product dp_d_d (
        .clk(clk),
        .rst(rst),
        .valid_in(1'b1),
        .a(dir),
        .b(dir),
        .a_dot_b(d_dot_d)
    );

    float16 n_dot_d;
    dot_product dp_n_d (
        .clk(clk),
        .rst(rst),
        .valid_in(1'b1),
        .a(normal),
        .b(dir),
        .a_dot_b(n_dot_d)
    );


    // P2: 15-stage
    // sqrt(n.n), sqrt(d.d), n.d
    localparam P2_STAGES = 15;
    
    float16 p2_mag_n;
    float_sqrt p2_sqrt_n (
        .aclk(clk),                                  // input wire aclk
        .s_axis_a_tvalid(1'b1),            // input wire s_axis_a_tvalid
        .s_axis_a_tdata(n_dot_n),              // input wire [15 : 0] s_axis_a_tdata
        // .m_axis_result_tvalid(m_axis_result_tvalid),  // output wire m_axis_result_tvalid
        .m_axis_result_tdata(p2_mag_n)    // output wire [15 : 0] m_axis_result_tdata
    );

    
    float16 p2_mag_d;
    float_sqrt p2_sqrt_d (
        .aclk(clk),                                  // input wire aclk
        .s_axis_a_tvalid(1'b1),            // input wire s_axis_a_tvalid
        .s_axis_a_tdata(d_dot_d),              // input wire [15 : 0] s_axis_a_tdata
        // .m_axis_result_tvalid(m_axis_result_tvalid),  // output wire m_axis_result_tvalid
        .m_axis_result_tdata(p2_mag_d)    // output wire [15 : 0] m_axis_result_tdata
    );

    // P3: 6-stage 
    // sqrt(n.n) * sqrt(d.d), n.d
    localparam P3_STAGES = 6;

    float16 p3_mag_n_d;
    float_multiply p3_mult_n_d (
        .aclk(clk),                                  // input wire aclk
        .s_axis_a_tvalid(1'b1),            // input wire s_axis_a_tvalid
        .s_axis_a_tdata(p2_mag_n),              // input wire [15 : 0] s_axis_a_tdata
        .s_axis_b_tvalid(1'b1),            // input wire s_axis_b_tvalid
        .s_axis_b_tdata(p2_mag_d),              // input wire [15 : 0] s_axis_b_tdata
        // .m_axis_result_tvalid(m_axis_result_tvalid),  // output wire m_axis_result_tvalid
        .m_axis_result_tdata(p3_mag_n_d)    // output wire [15 : 0] m_axis_result_tdata
    );

    // P4: 15-stage
    // n.d / (sqrt(n.n) * sqrt(d.d))
    localparam P4_STAGES = 15;

    float16 p4_n_dot_d;
    pipe #(
        .LENGTH(P2_STAGES + P3_STAGES),
        .WIDTH(16)
    ) pipe_p2_n_dot_d (
        .clk(clk),
        .rst(rst),
        .in(n_dot_d),
        .out(p4_n_dot_d)
    );

    float16 p4_intensity;
    float_divide p4_divide_n_d (
        .aclk(clk),                                  // input wire aclk
        .s_axis_a_tvalid(1'b1),            // input wire s_axis_a_tvalid
        .s_axis_a_tdata(p4_n_dot_d),              // input wire [15 : 0] s_axis_a_tdata
        .s_axis_b_tvalid(1'b1),            // input wire s_axis_b_tvalid
        .s_axis_b_tdata(p3_mag_n_d),              // input wire [15 : 0] s_axis_b_tdata
        // .m_axis_result_tvalid(m_axis_result_tvalid),  // output wire m_axis_result_tvalid
        .m_axis_result_tdata(p4_intensity)    // output wire [15 : 0] m_axis_result_tdata
    );

    // P5: 13-stage
    localparam P5_STAGES = 13;

    // 11-stage
    logic [15:0] p5_fx_intensity;
    logic p5_fx_sign;

    unit_float_to_fixed uff (
        .clk(clk),
        .rst(rst),
        .valid_in(1'b1),
        .flt(p4_intensity),
        // .valid_out(),
        .fx(p5_fx_intensity),
        .fx_sign(p5_fx_sign)
    );

    logic[15:0] p5_pixel;
    pipe#(
        .LENGTH(P1_STAGES + P2_STAGES + P3_STAGES + P4_STAGES + 11),
        .WIDTH(16)
    ) pipe_p5_color (
        .clk(clk),
        .rst(rst),
        .in(pixel_in),
        .out(p5_pixel)
    );

    // 1-stage for mult
    logic [20:0] p5_mult_r;
    logic [21:0] p5_mult_g;
    logic [20:0] p5_mult_b;
    logic p5_fx_sign_2;

    always_ff @( posedge clk ) begin
        p5_mult_r <= (p5_fx_intensity * p5_pixel[15:11]);
        p5_mult_g <= (p5_fx_intensity * p5_pixel[10:5]);
        p5_mult_b <= (p5_fx_intensity * p5_pixel[4:0]);
        p5_fx_sign_2 <= p5_fx_sign;
    end

    // 1-stage for final checks
    logic [4:0] r_out;
    logic [5:0] g_out;
    logic [4:0] b_out;

    always_ff @(posedge clk) begin
        if (p5_fx_sign_2) begin
            r_out <= 5'b0;
            g_out <= 6'b0;
            b_out <= 5'b0;
        end else begin
            r_out <= p5_mult_r[18:14];
            g_out <= p5_mult_g[19:14];
            b_out <= p5_mult_b[18:14];
        end
    end

    assign pixel_out = {r_out, g_out, b_out};

    localparam TOTAL_STAGES = P1_STAGES + P2_STAGES + P3_STAGES + P4_STAGES + P5_STAGES;
    pipe #(
        .LENGTH(TOTAL_STAGES),
        .WIDTH(1)
    ) pipe_valid (
        .clk(clk),
        .rst(rst),
        .in(valid_in),
        .out(valid_out)
    );

endmodule

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
    input wire [15:0] pixel_background,
    output logic busy,
    output ShapeAddr cur_shape_addr,
    output LightAddr cur_light_addr,
    output logic valid_out,
    output ScreenX pixel_x_out,
    output ScreenY pixel_y_out,
    output logic[15:0] pixel_value,
    output logic [1:0] shape_cast_debug_state
);
// camera at origin, pointing in negative z

    typedef enum { WAITING, INITIAL, LIGHTING, LIGHTING_NORMAL, GIVE_OUTPUT, GEN_NEXT_PIXEL } raytrace_state;
    raytrace_state state;
    logic sent_command;
    assign busy = (state != WAITING);
    assign valid_out = state == GIVE_OUTPUT;
    assign pixel_x_out = pixel_x;
    assign pixel_y_out = pixel_y;
    
    // send all raycasts for single pixel (all initial, then NUM_LIGHTS sets of lighting)
    // pipeline shape along with raycast

    ShapeAddr hit_shape_addr;
    logic [15:0] hit_color;
    vec3 hit_normal;

    vec3 light_dir;
    assign light_dir[0] = {~cur_light.xfor[15], cur_light.xfor[14:0]};
    assign light_dir[1] = {~cur_light.yfor[15], cur_light.yfor[14:0]};
    assign light_dir[2] = {~cur_light.zfor[15], cur_light.zfor[14:0]};
    // TODO: light_dir is different for point sources. for now, just assume directional

    // assume only 1 light for now
    assign cur_light_addr = 0;
    
    vec3 light_src;

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
                        sent_command <= 1'b0;
                        state <= INITIAL;
                    end else if (valid_inc_ray_x) begin
                        pixel_x <= pixel_x + 1;
                        camera_dir[0] <= inc_ray_x;
                        sent_command <= 1'b0;
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
                            if (shape_cast_hit) begin
                                // move to lighting when hit
                                light_src[0] <= shape_cast_intersection[0];
                                light_src[1] <= shape_cast_intersection[1];
                                light_src[2] <= shape_cast_intersection[2];
                                // cur_light_addr <= 0;
                                sent_command <= 1'b0;
                                state <= LIGHTING;
                                hit_color <= shape_cast_hit_shape.col;
                                hit_normal <= shape_cast_normal;
                                hit_shape_addr <= shape_cast_shape_addr;
                            end else begin
                                state <= GIVE_OUTPUT;
                                pixel_value <= pixel_background;
                            end
                        end
                        shape_cast_valid_in <= 1'b0;
                    end
                end else if (state == LIGHTING) begin
                    if (valid_light_1 && !sent_command) begin
                        sent_command <= 1'b1;
                        shape_cast_valid_in <= 1'b1;
                    end else begin
                        shape_cast_valid_in <= 1'b0;
                        if (sent_command) begin
                            if (shape_cast_valid_out) begin
                                if (shape_cast_hit) begin
                                    // no lighting - give black
                                    state <= GIVE_OUTPUT;
                                    pixel_value <= 16'b0;
                                end else begin
                                    // yes lighting!
                                    state <= LIGHTING_NORMAL;
                                    sent_command <= 1'b0;
                                end
                            end
                        end else begin
                            valid_light_1 <= 1'b1;
                        end
                    end
                end else if (state == LIGHTING_NORMAL) begin
                    sent_command <= 1'b1;
                    shape_cast_valid_in <= 1'b0;
                    if (lighting_valid_out) begin
                        // TODO: multiply with pixel value to get result
                        state <= GIVE_OUTPUT;
                        pixel_value <= lighting_pixel_out;
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

    logic [15:0] lighting_pixel_out;
    logic lighting_valid_out;

    lighting light (
        .clk(clk),
        .rst(rst),
        .valid_in(state == LIGHTING_NORMAL && !sent_command),
        .normal(hit_normal),
        .dir(light_dir),
        .pixel_in(hit_color),
        .valid_out(lighting_valid_out),
        .pixel_out(lighting_pixel_out)
    );


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
    vec3 shape_cast_normal;
    ShapeAddr shape_cast_shape_addr;


    // calculate raycast direction based on pixel values
    // pass src, dir, shape type, shape transform to the raycaster

    ShapeAddr cur_shape_addr_1;
    ShapeAddr cur_shape_addr_2;

    always_ff @( posedge clk ) begin 
        cur_shape_addr_1 <= cur_shape_addr;
        cur_shape_addr_2 <= cur_shape_addr_1;
    end

    Shape shape_cast_shape;
    always @(*) begin
        shape_cast_shape = cur_shape
        if (state == LIGHTING && cur_shape_addr_2 == hit_shape_addr) begin
            shape_case_shape.sType = stOff;
        end 
    end
    

    all_shapes_raycaster shape_cast (
        .clk(clk),
        .rst(rst),
        .valid_in(shape_cast_valid_in),
        .src(state == LIGHTING ? light_src : camera_src),
        .dir(state == LIGHTING ? light_dir : camera_dir),
        .cur_shape(shape_cast_shape),
        .read_shape_addr(cur_shape_addr),
        .valid_out(shape_cast_valid_out),
        .hit(shape_cast_hit),
        .intersection(shape_cast_intersection),
        .hit_shape(shape_cast_hit_shape),
        .intersection_normal(shape_cast_normal),
        .hit_shape_addr(shape_cast_shape_addr),
        .debug_state(shape_cast_debug_state)
    );

endmodule

`default_nettype wire