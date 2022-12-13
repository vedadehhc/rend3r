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
    input Camera cur_camera,
    input wire fin_raycast_valid,
    input wire fin_raycast_hit,
    input wire float16 fin_raycast_sq_distance,
    input vec3 fin_raycast_intersection,
    output logic busy,
    output ShapeAddr cur_shape_addr,
    output LightAddr cur_light_addr,
    output logic next_raycast_valid,
    output vec3 next_raycast_src,
    output vec3 next_raycast_dir,
    output ShapeType next_raycast_shape_type,
    output vec3 next_raycast_shape_trans_inv,
    output quaternion next_raycast_shape_rot,
    output vec3 next_raycast_shape_scale_inv
);
// camera at origin, pointing in negative z

    typedef enum { WAITING, INITIAL, FINISHED_INITIAL, LIGHTING, FINISHED_LIGHTING } raytrace_state;
    raytrace_state state;
    assign busy = (state != WAITING);

    ScreenX cur_pixel_x;
    ScreenY cur_pixel_y;
    
    ScreenX cur_pixel_x_1;
    ScreenY cur_pixel_y_1;

    ScreenX cur_pixel_x_2;
    ScreenY cur_pixel_y_2;
    
    // send all raycasts for single pixel (all initial, then NUM_LIGHTS sets of lighting)
    // pipeline shape along with raycast
    
    logic shape_valid_1;
    logic shape_valid_2;

    ShapeAddr cur_shape_addr_1;
    ShapeAddr cur_shape_addr_2;
    

    always_ff @( posedge clk ) begin 
        if (rst) begin
            cur_shape_addr <= 0;
            shape_valid_1 <= 1'b0;
            shape_valid_2 <= 1'b0;
            state <= WAITING;
            cur_pixel_x <= 0;
            cur_pixel_y <= 0;
        end else begin
            if (execInst_valid && (execInst.iType == opFrame || execInst.iType == opRender)) begin
                if (execInst.iType == opFrame) begin
                    cur_shape_addr <= 0;
                    shape_valid_1 <= 1'b0;
                    state <= INITIAL;
                    cur_pixel_x <= 0;
                    cur_pixel_y <= 0;
                end else if (execInst.iType == opRender) begin
                    cur_shape_addr <= 0;
                    shape_valid_1 <= 1'b0;
                    state <= WAITING;
                    cur_pixel_x <= 0;
                    cur_pixel_y <= 0;
                end
            end else if (busy && mem_ready) begin
                if (cur_shape_addr == (NUM_SHAPES-1)) begin // finished with all shapes
                    cur_shape_addr <= 0;
                    if (state == INITIAL) begin // go to next state for same pixel
                        state <= FINISHED_INITIAL;
                    end else if (state == LIGHTING) begin // done with this pixel
                        state <= FINISHED_LIGHTING;
                    end
                    shape_valid_1 <= 1'b1;
                end else if (state == FINISHED_INITIAL) begin
                    shape_valid_1 <= 1'b0;

                    // if received all results, then go to lighting
                        // state <= LIGHTING;
                end else if (state == FINISHED_LIGHTING) begin
                    shape_valid_1 <= 1'b0;

                    // if received all results, then do the following:               
                        // if (cur_pixel_y == (SCREEN_HEIGHT-1) && cur_pixel_x == (SCREEN_WIDTH-1)) begin // done with all pixels
                        //     state <= WAITING;
                        // end else begin // go to next pixel
                        //     if (cur_pixel_x == SCREEN_WIDTH-1) begin // end of row
                        //         cur_pixel_x <= 0;
                        //         cur_pixel_y <= cur_pixel_y + 1;
                        //     end else begin
                        //         cur_pixel_x <= cur_pixel_x + 1;
                        //     end
                        //     state <= INITIAL;
                        //     cur_shape_addr <= 0;
                        // end
                end else begin
                    cur_shape_addr <= cur_shape_addr + 1;
                    shape_valid_1 <= 1'b1;
                end
            end else begin
                shape_valid_1 <= 1'b0;
            end
            // Pipelining
            shape_valid_2 <= shape_valid_1;
            
            cur_shape_addr_1 <= cur_shape_addr;
            cur_shape_addr_2 <= cur_shape_addr_1;

            cur_pixel_x_1 <= cur_pixel_x;
            cur_pixel_x_2 <= cur_pixel_x_1;

            cur_pixel_y_1 <= cur_pixel_y;
            cur_pixel_y_2 <= cur_pixel_y_1;
        end
    end


    // calculate raycast direction based on pixel values
    // pass src, dir, shape type, shape transform to the raycaster


endmodule

`default_nettype wire