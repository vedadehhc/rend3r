`default_nettype none
`timescale 1ns / 1ps

import proctypes::*;


// SWITCHES:
// sw[15] = use instruction bank
module top_level(
    input wire clk_100mhz, //clock @ 100 mhz
    input wire btnc, //btnc (used for reset)
    input wire btnu, //btnu
    input wire btnl, //btnl
    input wire [15:0] sw,
    input wire eth_crsdv,
    input wire [1:0] eth_rxd,
    output logic [15:0] led, // leds
    output logic eth_rstn,
    output logic eth_refclk,
    output logic ca, cb, cc, cd, ce, cf, cg,
    output logic [7:0] an
);
    logic rst;
    assign rst = btnc;
    assign eth_rstn = ~btnc;

    logic clk_50mhz;
    assign eth_refclk = clk_50mhz;

    logic buf_clk_100mhz;

    divider eth_clk_gen(.clk(clk_100mhz), .ethclk(clk_50mhz), .clk_divider(buf_clk_100mhz));

    logic ether_axiov;
    logic [1:0] ether_axiod;

    ether ethernet(
        .clk(clk_50mhz),
        .rst(rst),
        .rxd(eth_rxd),
        .crsdv(eth_crsdv),
        .axiov(ether_axiov),
        .axiod(ether_axiod)
    );

    logic bo_axiov;
    logic [1:0] bo_axiod;

    bitorder bo (
        .clk(clk_50mhz),
        .rst(rst),
        .axiiv(ether_axiov),
        .axiid(ether_axiod),
        .axiov(bo_axiov),
        .axiod(bo_axiod)
    );

    logic fw_axiov;
    logic [1:0] fw_axiod;

    firewall fw (
        .clk(clk_50mhz),
        .rst(rst),
        .axiiv(bo_axiov),
        .axiid(bo_axiod),
        .axiov(fw_axiov),
        .axiod(fw_axiod)
    );

    logic agg_axiov;
    logic [31:0] agg_axiod;

    aggregate agg (
        .clk(clk_50mhz),
        .rst(rst),
        .axiiv(fw_axiov),
        .axiid(fw_axiod),
        .axiov(agg_axiov),
        .axiod(agg_axiod)
    );

    logic [31:0] ssc_in;
    logic got_valid;
    always_ff @(posedge clk_50mhz) begin
        if (rst) begin
            ssc_in <= 0;
            got_valid <= 0;
        end else if (agg_axiov) begin
            ssc_in <= agg_axiod;
        end
        if ((~rst) & bo_axiov) begin 
            got_valid <= 1'b1;
        end
    end

    logic parse_valid_out;
    DecodedInst dInst;

    logic use_instruction_bank;
    assign use_instruction_bank = sw[15];

    // xilinx_single_port_ram_read_first #(
    //     .RAM_WIDTH(32),                       // Specify RAM data width
    //     .RAM_DEPTH(NUM_INSTRUCTIONS),                     // Specify RAM depth (number of entries)
    //     .RAM_PERFORMANCE("HIGH_PERFORMANCE"), // Select "HIGH_PERFORMANCE" or "LOW_LATENCY" 
    //     .INIT_FILE(`FPATH(main.hex))          // Specify name/location of RAM initialization file if using one (leave blank if not)
    // ) instruction_bank (
    //     .addra(addra),     // Address bus, width determined from RAM_DEPTH
    //     .dina(dina),       // RAM input data, width determined from RAM_WIDTH
    //     .clka(clka),       // Clock
    //     .wea(wea),         // Write enable
    //     .ena(ena),         // RAM Enable, for additional power savings, disable port when not in use
    //     .rsta(rsta),       // Output reset (does not affect memory contents)
    //     .regcea(regcea),   // Output register enable
    //     .douta(douta)      // RAM output data, width determined from RAM_WIDTH
    // );
    
    logic [NUM_INSTRUCTIONS_WIDTH-1:0] pc;
    parser parse(
        .clk(clk_50mhz),
        .rst(rst),
        .instruction(agg_axiod),
        .valid_in(1'b1),
        .valid_out(parse_valid_out),
        .dInst(dInst),
        .pc(pc)
    );

    assign led[15:11] = dInst.prop;
    assign led[8:3] = dInst.iType == opLightSet ? dInst.lIndex : dInst.sIndex[5:0];
    assign led[2:0] = dInst.iType;

    logic mem_ready;
    Camera cur_camera;
    Light cur_light;
    logic [GEOMETRY_WIDTH-1:0] cur_geo;

    execute exec (
        .clk_50mhz(clk_50mhz),
        .clk_100mhz(buf_clk_100mhz),
        .rst(rst),
        .dInst_valid(parse_valid_out),
        .dInst(dInst),
        .pc(pc),
        .memory_ready(mem_ready),
        .cur_camera(cur_camera),
        .cur_light(cur_light),
        .cur_geo(cur_geo)
    );

    // rasterization controller 
    // should iterate through all triangles and pass to rasterizer


    
    seven_segment_controller ssc (
        .clk_in(clk_50mhz),
        .rst_in(rst),
        .val_in({cur_camera.xloc, cur_camera.yloc}),
        .cat_out({cg, cf, ce, cd, cc, cb, ca}),
        .an_out(an)
    );

    logic fcs_done;
    logic fcs_done_old;
    logic fcs_kill;

    cksum fcs(
        .clk(clk_50mhz),
        .rst(rst),
        .axiiv(ether_axiov),
        .axiid(ether_axiod),
        .done(fcs_done),
        .kill(fcs_kill)
    );

    logic [13:0] counter;
    // assign led[13] = got_valid;

    always_ff @( posedge clk_50mhz ) begin
        if (rst) begin
            counter <= 16'b0;
            fcs_done_old <= 1'b0;
        end else begin
            fcs_done_old <= fcs_done;
            if (fcs_done & (~fcs_done_old) & fw_axiov) begin
                counter <= counter + 1;
            end
        end
    end

endmodule

`default_nettype wire