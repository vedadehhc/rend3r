`default_nettype none
`timescale 1ns / 1ps

import proctypes::*;

module execute (
    input wire clk_50mhz,
    input wire clk_100mhz,
    input wire rst,
    input wire dInst_valid_in,
    input wire DecodedInst dInst_in,
    input wire InstructionAddr pc,
    input wire [LIGHT_ADDR_WIDTH-1:0] light_read_addr,
    input wire [GEOMETRY_ADDR_WIDTH-1:0] geometry_read_addr,
    output logic dInst_valid_out,
    output DecodedInst dInst_out,
    output logic memory_ready,
    output Camera cur_camera,
    output Light cur_light,
    output logic [GEOMETRY_WIDTH-1:0] cur_geo
);
    // write the last (invalid) instruction as well 
    logic write_valid;
    always_ff @( posedge clk_50mhz ) begin
        if (rst) begin
            write_valid <= 1'b0;
        end else begin
            write_valid <= dInst_valid_in;
        end
    end

    logic [DECODED_INSTRUCTION_WIDTH + NUM_INSTRUCTIONS_WIDTH:0] dInst_flat;
    assign dInst_flat = {dInst_valid_in, dInst_in, pc};

    xilinx_true_dual_port_read_first_2_clock_ram #(
        .RAM_WIDTH(DECODED_INSTRUCTION_WIDTH + NUM_INSTRUCTIONS_WIDTH + 1),                       // Specify RAM data width
        .RAM_DEPTH(2),                     // Specify RAM depth (number of entries)
        .RAM_PERFORMANCE("LOW_LATENCY"), // Select "HIGH_PERFORMANCE" or "LOW_LATENCY"
        .INIT_FILE("")                        // Specify name/location of RAM initialization file if using one (leave blank if not)
    ) instruction_buffer (
        .addra(1'b0),   // Port A address bus, width determined from RAM_DEPTH
        .addrb(1'b0),   // Port B address bus, width determined from RAM_DEPTH
        .dina(dInst_flat),     // Port A RAM input data, width determined from RAM_WIDTH
        .dinb(),     // Port B RAM input data, width determined from RAM_WIDTH
        .clka(clk_50mhz),     // Port A clock
        .clkb(clk_100mhz),     // Port B clock
        .wea(dInst_valid_in || write_valid),       // Port A write enable
        .web(1'b0),       // Port B write enable
        .ena(1'b1),       // Port A RAM Enable, for additional power savings, disable port when not in use
        .enb(1'b1),       // Port B RAM Enable, for additional power savings, disable port when not in use
        .rsta(rst),     // Port A output reset (does not affect memory contents)
        .rstb(rst),     // Port B output reset (does not affect memory contents)
        .regcea(1'b0), // Port A output register enable
        .regceb(1'b0), // Port B output register enable
        .douta(),   // Port A RAM output data, width determined from RAM_WIDTH
        .doutb(sysclk_dInst_flat)    // Port B RAM output data, width determined from RAM_WIDTH
    );

    logic [DECODED_INSTRUCTION_WIDTH + NUM_INSTRUCTIONS_WIDTH:0] sysclk_dInst_flat;


    // memory bank - handles writes due to instructions and gives latency 2 reads to camera, light, geo
    memory_bank mem_bank (
        .clk_100mhz(clk_100mhz),
        .rst(rst),
        .dInst_valid(sysclk_dInst_flat[DECODED_INSTRUCTION_WIDTH + NUM_INSTRUCTIONS_WIDTH]),
        .dInst_flat(sysclk_dInst_flat[DECODED_INSTRUCTION_WIDTH + NUM_INSTRUCTIONS_WIDTH-1:0]),
        .light_read_addr(light_read_addr),
        .geometry_read_addr(geometry_read_addr),
        .dInst_out(dInst_out),
        .output_enabled(memory_ready),
        .camera_output(cur_camera),
        .light_output(cur_light),
        .geometry_output(cur_geo)
    );
endmodule

`default_nettype wire