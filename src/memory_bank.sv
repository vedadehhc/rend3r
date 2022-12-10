`default_nettype none
`timescale 1ns / 1ps

import proctypes::*;

// TODO: issue - bank 1, bank 2 don't sync across frames. need a sync during new-frame
// possible fixes:
// 1. read from bank 1, write to bank 2
//      this allows us to update using old data
//      SW: requires some update to an asset on frame x+1 if asset was updated on frame x
//          if asset is updated anyways, this is fine. worst case, 2x instructions
//          more instructions seems fine, since rendering has slow framerate anyways.
//      SW: can have at most one update to every property on each frame (subsequent are ignored) - this seems fine
// 2. SW: require holding of values for two frames
//      this seems worse than option 1
// 3. stall the pipeline when reached a new-frame to allow copying of dirty data
//      requires a FIFO instruction buffer (hard)
//      also should then keep track of dirty data or copy all (slow)
// 4. buffer all modifications to bank 1 made in frame x, write to bank 2 in frame x+1
//      could use 2nd port to write twice as fast
//      need to make sure new changes are applied after old changes
//      seems difficult to manage dirty bits, etc.
// 5. buffer all commands from ethernet first, then stall
//
module memory_bank(
    input wire clk_100mhz,
    input wire rst,
    input wire dInst_valid,
    input wire [DECODED_INSTRUCTION_WIDTH + NUM_INSTRUCTIONS_WIDTH-1:0] dInst_flat,
    input wire LightAddr light_read_addr,
    input wire GeometryAddr geometry_read_addr,
    output logic dInst_valid_out,
    output DecodedInst dInst_out,
    output logic output_enabled,
    output Camera camera_output,
    output Light light_output,
    output logic [GEOMETRY_WIDTH-1:0] geometry_output
);

    DecodedInst dInst_1;
    assign dInst_1 = dInst_flat[DECODED_INSTRUCTION_WIDTH + NUM_INSTRUCTIONS_WIDTH-1:NUM_INSTRUCTIONS_WIDTH];

    InstructionAddr pc_1;
    assign pc_1 = dInst_flat[NUM_INSTRUCTIONS_WIDTH-1:0];
    
    logic valid_1;
    assign valid_1 = dInst_valid;
    
    DecodedInst dInst_2;
    InstructionAddr pc_2;
    logic valid_2;

    DecodedInst dInst_3;
    InstructionAddr pc_3;
    logic valid_3;
    
    DecodedInst dInst_4;
    InstructionAddr pc_4;
    logic valid_4;

    assign dInst_out = dInst_4;
    assign dInst_valid_out = valid_4;

    always_ff @( posedge clk_100mhz ) begin
        if (rst) begin 
            dInst_2 <= {(DECODED_INSTRUCTION_WIDTH){1'b0}};
            pc_2 <= {(NUM_INSTRUCTIONS_WIDTH){1'b1}};
            valid_2 <= 1'b0;

            dInst_3 <= {(DECODED_INSTRUCTION_WIDTH){1'b0}};
            pc_3 <= {(NUM_INSTRUCTIONS_WIDTH){1'b1}};
            valid_3 <= 1'b0;

            dInst_4 <= {(DECODED_INSTRUCTION_WIDTH){1'b0}};
            pc_4 <= {(NUM_INSTRUCTIONS_WIDTH){1'b1}};
            valid_4 <= 1'b0;
        end else begin 
            dInst_2 <= dInst_1;
            pc_2 <= pc_1;
            valid_2 <= valid_1;

            dInst_3 <= dInst_2;
            pc_3 <= pc_2;
            valid_3 <= valid_2;

            dInst_4 <= dInst_3;
            pc_4 <= pc_3;
            valid_4 <= valid_3;
        end
    end

    /// perform reads in stage 1, writes in stage 4
    /// result of read in stage 3

    // write enable for different data types
    logic we_geometry;
    logic [GEOMETRY_ADDR_WIDTH-1:0] addr_geometry;
    logic [GEOMETRY_WIDTH-1:0] read_geometry_3;
    Triangle triangle_3_4;
    Shape shape_3_4;
    logic [GEOMETRY_WIDTH-1:0] write_geometry_4;

    logic [GEOMETRY_WIDTH-1:0] write_geometry_4_bypass;

    logic we_light;
    logic [LIGHT_WIDTH-1:0] read_light_3;
    Light light_3_4;
    logic [LIGHT_WIDTH-1:0] write_light_4;
    logic [LIGHT_ADDR_WIDTH-1:0] addr_light;

    logic [LIGHT_WIDTH-1:0] write_light_4_bypass;

    logic we_camera;
    logic [CAMERA_WIDTH-1:0] read_camera_3;
    Camera camera_3_4;
    logic [CAMERA_WIDTH-1:0] write_camera_4;

    logic [CAMERA_WIDTH-1:0] write_camera_4_bypass;
    
    logic valid_4_bypass;
    DecodedInst dInst_4_bypass;
    always_ff @( posedge clk_100mhz ) begin
        valid_4_bypass <= valid_4;
        dInst_4_bypass <= dInst_4;
        write_geometry_4_bypass <= write_geometry_4;
        write_light_4_bypass <= write_light_4;
        write_camera_4_bypass <= write_camera_4;
    end

    always @(*) begin 
        camera_3_4 = read_camera_3;
        case (dInst_3.prop)
            cpXLocation:    camera_3_4.xloc = dInst_3.data;
            cpYLocation:    camera_3_4.yloc = dInst_3.data;
            cpZLocation:    camera_3_4.zloc = dInst_3.data;
            cpXForward:     camera_3_4.xfor = dInst_3.data;
            cpYForward:     camera_3_4.yfor = dInst_3.data;
            cpZForward:     camera_3_4.zfor = dInst_3.data;
            cpXUp:          camera_3_4.xup  = dInst_3.data;
            cpYUp:          camera_3_4.yup  = dInst_3.data;
            cpZUp:          camera_3_4.zup  = dInst_3.data;
            cpNearClip:     camera_3_4.nclip= dInst_3.data;
            cpFarClip:      camera_3_4.fclip= dInst_3.data;
            cpFovHor:       camera_3_4.hfov = dInst_3.data;
            cpFovVer:       camera_3_4.vfov = dInst_3.data;
        endcase

        light_3_4 = read_light_3;
        case (dInst_3.prop)
            lpType:             light_3_4.lType = LightType'(dInst_3.data[1:0]);
            lpXLocation:        light_3_4.xloc = dInst_3.data;
            lpYLocation:        light_3_4.yloc = dInst_3.data;
            lpZLocation:        light_3_4.zloc = dInst_3.data;
            lpXForward:         light_3_4.xfor = dInst_3.data;
            lpYForward:         light_3_4.yfor = dInst_3.data;
            lpZForward:         light_3_4.zfor = dInst_3.data;
            lpColor:            light_3_4.col  = dInst_3.data;
            lpIntensity:        light_3_4.intensity = dInst_3.data;
        endcase

        if (RENDERING_MODE == renderRasterization) begin
            triangle_3_4 = read_geometry_3;
            case (dInst_3.prop)
                tpX1: begin
                    triangle_3_4.x1 = dInst_1.data;
                end 
                tpY1: begin
                    triangle_3_4.y1 = dInst_1.data;
                end 
                tpZ1: begin
                    triangle_3_4.z1 = dInst_1.data;
                end 
                tpX2: begin
                    triangle_3_4.x2 = dInst_1.data;
                end 
                tpY2: begin
                    triangle_3_4.y2 = dInst_1.data;
                end 
                tpZ2: begin
                    triangle_3_4.z2 = dInst_1.data;
                end 
                tpX3: begin
                    triangle_3_4.x3 = dInst_1.data;
                end 
                tpY3: begin
                    triangle_3_4.y3 = dInst_1.data;
                end 
                tpZ3: begin
                    triangle_3_4.z3 = dInst_1.data;
                end 
                tpColor: begin
                    triangle_3_4.col = dInst_1.data;
                end
                tpMaterial: begin
                    triangle_3_4.mat = dInst_1.data[1:0];
                end
            endcase
            case (dInst_3.prop2)
                tpX1: begin
                    triangle_3_4.x1 = dInst_1.data2;
                end 
                tpY1: begin
                    triangle_3_4.y1 = dInst_1.data2;
                end 
                tpZ1: begin
                    triangle_3_4.z1 = dInst_1.data2;
                end 
                tpX2: begin
                    triangle_3_4.x2 = dInst_1.data2;
                end 
                tpY2: begin
                    triangle_3_4.y2 = dInst_1.data2;
                end 
                tpZ2: begin
                    triangle_3_4.z2 = dInst_1.data2;
                end 
                tpX3: begin
                    triangle_3_4.x3 = dInst_1.data2;
                end 
                tpY3: begin
                    triangle_3_4.y3 = dInst_1.data2;
                end 
                tpZ3: begin
                    triangle_3_4.z3 = dInst_1.data2;
                end 
                tpColor: begin
                    triangle_3_4.col = dInst_1.data2;
                end
                tpMaterial: begin
                    triangle_3_4.mat = dInst_1.data2[1:0];
                end
            endcase
        end else if (RENDERING_MODE == renderRaytracing) begin
            // TODO: fill in 
        end
    end

    always_ff @( posedge clk_100mhz ) begin 
        write_light_4 <= light_3_4;
        write_camera_4 <= camera_3_4;
        if (RENDERING_MODE == renderRasterization) begin
            write_geometry_4 <= triangle_3_4;
        end else if (RENDERING_MODE == renderRaytracing) begin
            write_geometry_4 <= shape_3_4;
        end
    end

    always @(*) begin
        if (pc_1 != pc_2 && valid_1) begin
            // inst: A, B, B, C
            // new instruction - read A in stage 1
            we_geometry = 1'b0;
            we_light = 1'b0;
            we_camera = 1'b0;
            case (dInst_1.iType)
                opShapeSet : begin 
                    addr_geometry = dInst_1.sIndex;
                end
                opLightSet : begin
                    addr_light = dInst_1.lIndex;
                end
                opCameraSet: begin

                end
            endcase
        end else if (pc_3 == pc_4 && valid_3 && valid_4) begin
            // inst: A, A, B, B
            // write B in stage 4
            we_geometry = 1'b0;
            we_light = 1'b0;
            we_camera = 1'b0;
            case (dInst_4.iType)
                opShapeSet : begin 
                    addr_geometry = dInst_4.sIndex;
                    we_geometry = 1'b1;
                end
                opLightSet : begin
                    addr_light = dInst_4.lIndex;
                    we_light = 1'b1;
                end
                opCameraSet: begin
                    we_camera = 1'b1;
                end
            endcase
        end
    end

    logic bram_write_index;
    logic bram_read_index;
    assign bram_read_index = ~bram_write_index;
    
    always_ff @( posedge clk_100mhz ) begin
        if (rst) begin
            bram_write_index <= 1'b0;
            output_enabled <= 1'b0;
        end else begin
            if (pc_2 == pc_3 && valid_2 && valid_3) begin 
                // instruction pipe: C, A, A, B
                if (dInst_2.iType == opFrame) begin
                    bram_write_index <= ~bram_write_index;
                    output_enabled <= 1'b1;
                end else if (dInst_2.iType == opRender) begin
                    output_enabled <= 1'b0;
                end
            end
        end
    end

    
    logic [CAMERA_WIDTH-1:0] read_camera_3_out [1:0];
    logic [LIGHT_WIDTH-1:0] read_light_3_out [1:0];
    logic [GEOMETRY_WIDTH-1:0] read_geometry_3_out [1:0];
    
    always @(*) begin 
        read_camera_3 = read_camera_3_out[bram_write_index];
        read_light_3 = read_light_3_out[bram_write_index];
        read_geometry_3 = read_geometry_3_out[bram_write_index];
        if (valid_4_bypass && dInst_4_bypass.iType == dInst_3.iType) begin
            if (dInst_4_bypass.iType == opCameraSet) begin
                read_camera_3 = write_camera_4_bypass;
            end
            if (dInst_4_bypass.iType == opLightSet && dInst_4_bypass.lIndex == dInst_3.lIndex) begin
                read_light_3 = write_light_4_bypass;
            end
            if (dInst_4_bypass.iType == opShapeSet && dInst_4_bypass.sIndex == dInst_3.sIndex) begin
                read_geometry_3 = write_geometry_4_bypass;
            end
        end
    end

    logic [CAMERA_WIDTH-1:0] camera_out [1:0];
    logic [LIGHT_WIDTH-1:0] light_out [1:0];
    logic [GEOMETRY_WIDTH-1:0] geometry_out [1:0];

    generate
        genvar i;
        for (i = 0; i < 2; i = i + 1) begin
            xilinx_true_dual_port_read_first_2_clock_ram #(
                .RAM_WIDTH(GEOMETRY_WIDTH),                       // Specify RAM data width
                .RAM_DEPTH(GEOMETRY_DEPTH),                     // Specify RAM depth (number of entries)
                .RAM_PERFORMANCE("HIGH_PERFORMANCE"), // Select "HIGH_PERFORMANCE" or "LOW_LATENCY"
                .INIT_FILE("")                        // Specify name/location of RAM initialization file if using one (leave blank if not)
            ) geometry_ram (
                .addra(addr_geometry),   // Port A address bus, width determined from RAM_DEPTH
                .addrb(geometry_read_addr),   // Port B address bus, width determined from RAM_DEPTH
                .dina(write_geometry_4),     // Port A RAM input data, width determined from RAM_WIDTH
                .dinb(),     // Port B RAM input data, width determined from RAM_WIDTH
                .clka(clk_100mhz),     // Port A clock
                .clkb(clk_100mhz),     // Port B clock
                .wea(we_geometry && (i == bram_write_index)),       // Port A write enable
                .web(1'b0),       // Port B write enable
                .ena(1'b1),       // Port A RAM Enable, for additional power savings, disable port when not in use
                .enb(1'b1),       // Port B RAM Enable, for additional power savings, disable port when not in use
                .rsta(rst),     // Port A output reset (does not affect memory contents)
                .rstb(rst),     // Port B output reset (does not affect memory contents)
                .regcea(1'b1), // Port A output register enable
                .regceb(1'b1), // Port B output register enable
                .douta(read_geometry_3_out[i]),   // Port A RAM output data, width determined from RAM_WIDTH
                .doutb(geometry_out[i])    // Port B RAM output data, width determined from RAM_WIDTH
            );

            xilinx_true_dual_port_read_first_2_clock_ram #(
                .RAM_WIDTH(LIGHT_WIDTH),                       // Specify RAM data width
                .RAM_DEPTH(NUM_LIGHTS),                     // Specify RAM depth (number of entries)
                .RAM_PERFORMANCE("HIGH_PERFORMANCE"), // Select "HIGH_PERFORMANCE" or "LOW_LATENCY"
                .INIT_FILE("")                        // Specify name/location of RAM initialization file if using one (leave blank if not)
            ) light_ram (
                .addra(addr_light),   // Port A address bus, width determined from RAM_DEPTH
                .addrb(light_read_addr),   // Port B address bus, width determined from RAM_DEPTH
                .dina(write_light_4),     // Port A RAM input data, width determined from RAM_WIDTH
                .dinb(),     // Port B RAM input data, width determined from RAM_WIDTH
                .clka(clk_100mhz),     // Port A clock
                .clkb(clk_100mhz),     // Port B clock
                .wea(we_light && (i == bram_write_index)),       // Port A write enable
                .web(1'b0),       // Port B write enable
                .ena(1'b1),       // Port A RAM Enable, for additional power savings, disable port when not in use
                .enb(1'b1),       // Port B RAM Enable, for additional power savings, disable port when not in use
                .rsta(rst),     // Port A output reset (does not affect memory contents)
                .rstb(rst),     // Port B output reset (does not affect memory contents)
                .regcea(1'b1), // Port A output register enable
                .regceb(1'b1), // Port B output register enable
                .douta(read_light_3_out[i]),   // Port A RAM output data, width determined from RAM_WIDTH
                .doutb(light_out[i])    // Port B RAM output data, width determined from RAM_WIDTH
            );

            xilinx_true_dual_port_read_first_2_clock_ram #(
                .RAM_WIDTH(CAMERA_WIDTH),                       // Specify RAM data width
                .RAM_DEPTH(2),                     // Specify RAM depth (number of entries)
                .RAM_PERFORMANCE("HIGH_PERFORMANCE"), // Select "HIGH_PERFORMANCE" or "LOW_LATENCY"
                .INIT_FILE("")                        // Specify name/location of RAM initialization file if using one (leave blank if not)
            ) camera_ram (
                .addra(1'b0),   // Port A address bus, width determined from RAM_DEPTH
                .addrb(1'b0),   // Port B address bus, width determined from RAM_DEPTH
                .dina(write_camera_4),     // Port A RAM input data, width determined from RAM_WIDTH
                .dinb(),     // Port B RAM input data, width determined from RAM_WIDTH
                .clka(clk_100mhz),     // Port A clock
                .clkb(clk_100mhz),     // Port B clock
                .wea(we_camera && (i == bram_write_index)),       // Port A write enable
                .web(1'b0),       // Port B write enable
                .ena(1'b1),       // Port A RAM Enable, for additional power savings, disable port when not in use
                .enb(1'b1),       // Port B RAM Enable, for additional power savings, disable port when not in use
                .rsta(rst),     // Port A output reset (does not affect memory contents)
                .rstb(rst),     // Port B output reset (does not affect memory contents)
                .regcea(1'b1), // Port A output register enable
                .regceb(1'b1), // Port B output register enable
                .douta(read_camera_3_out[i]),   // Port A RAM output data, width determined from RAM_WIDTH
                .doutb(camera_out[i])    // Port B RAM output data, width determined from RAM_WIDTH
            );
        end
    endgenerate

    assign camera_output = camera_out[bram_read_index];
    assign light_output = light_out[bram_read_index];
    assign geometry_output = geometry_out[bram_read_index];

endmodule

`default_nettype wire