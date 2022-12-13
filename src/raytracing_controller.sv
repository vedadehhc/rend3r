`default_nettype none
`timescale 1ns / 1ps

import proctypes::*;

// takes (RAYCASTER_STAGES + NUM_SHAPES + O(1)) * (NUM_LIGHTS + 1) * NUM_PIXELS + O(1) cycles 
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
);
// camera at origin, pointing in negative z

    typedef enum { WAITING, INITIAL, LIGHTING, GEN_NEXT_PIXEL } raytrace_state;
    raytrace_state state;
    assign busy = (state != WAITING);
    
    // send all raycasts for single pixel (all initial, then NUM_LIGHTS sets of lighting)
    // pipeline shape along with raycast

    always_ff @( posedge clk ) begin 
        if (rst) begin
            state <= WAITING;
        end else begin
            if (execInst_valid && (execInst.iType == opFrame || execInst.iType == opRender)) begin
                if (execInst.iType == opFrame) begin
                    state <= INITIAL;
                end else if (execInst.iType == opRender) begin
                    state <= WAITING;
                end
            end else if (busy && mem_ready) begin
                
            end else begin
                
            end
        end
    end


    // calculate raycast direction based on pixel values
    // pass src, dir, shape type, shape transform to the raycaster



    all_shapes_raycaster shape_cast (
        .clk(clk),
        .rst(rst),
        .valid_in(),
        .src(),
        .dir(),
        .cur_shape(cur_shape),
        .read_shape_addr(cur_shape_addr),
        .valid_out(),
        .hit(),
        .intersection(),
        .hit_shape(),
    );

endmodule

`default_nettype wire