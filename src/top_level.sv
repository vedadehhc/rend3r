`default_nettype none
`timescale 1ns / 1ps

import proctypes::*;

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

    divider eth_clk_gen(.clk(clk_100mhz), .ethclk(clk_50mhz));

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

    logic parse_valid_out;
    DecodedInst dInst;

    parser parse(
        .clk(clk_50mhz),
        .rst(rst),
        .instruction({16'b0, sw}),
        .valid_in(1'b1),
        .valid_out(parse_valid_out),
        .dInst(dInst)
    );

    assign led[15:11] = dInst.prop;
    assign led[8:3] = dInst.iType == opLightSet ? dInst.lIndex : dInst.sIndex[5:0];
    assign led[2:0] = dInst.iType;
    
    vec3 src;
    assign src[0] = 16'h0;
    assign src[1] = 16'h0;
    assign src[2] = 16'h0;

    vec3 dir;
    assign dir[0] = 16'h3C00;
    assign dir[1] = {5'b00111, sw[15:8], 3'b000};
    assign dir[2] = 16'h0000;
    
    quaternion rot;
    assign rot[0] = 16'h3C00;
    assign rot[1] = 16'h0;
    assign rot[2] = 16'h0;
    assign rot[3] = 16'h0;

    vec3 scale;
    assign scale[0] = {5'b00111, sw[7:0], 3'b000};
    assign scale[1] = 16'h3C00;
    assign scale[2] = 16'h3C00;

    logic raycast_valid;
    logic raycast_hit;
    float16 raycast_sq_distance;
    vec3 raycast_intersection;

    raycaster raycast (
        .clk(clk_50mhz),
        .rst(rst),
        .valid_in(1'b1),
        .src(src),
        .dir(dir),
        .shape_type(stSphere),
        .shape_trans_inv(src),
        .shape_rot(rot),
        .shape_scale_inv(scale),
        .valid_out(raycast_valid),
        .hit(raycast_hit),
        .sq_distance(raycast_sq_distance),
        .intersection(raycast_intersection)
    );


    vec3 dir2;
    assign dir2[0] = {5'b00111, sw[15:8], 3'b000};
    assign dir2[1] = 16'h3C00;
    assign dir2[2] = 16'h0000;

    vec3 scale2;
    assign scale2[0] = 16'h3C00;
    assign scale2[1] = {5'b00111, sw[7:0], 3'b000};
    assign scale2[2] = 16'h3C00;

    logic raycast_valid_2;
    logic raycast_hit_2;
    float16 raycast_sq_distance_2;
    vec3 raycast_intersection_2;
    
    // raycaster raycast2 (
    //     .clk(clk_50mhz),
    //     .rst(rst),
    //     .valid_in(1'b1),
    //     .src(src),
    //     .dir(dir2),
    //     .shape_type(stSphere),
    //     .shape_trans_inv(src),
    //     .shape_rot(rot),
    //     .shape_scale_inv(scale2),
    //     .valid_out(raycast_valid_2),
    //     .hit(raycast_hit_2),
    //     .sq_distance(raycast_sq_distance_2),
    //     .intersection(raycast_intersection_2)
    // );


    assign led[10:9] = btnl ? {raycast_valid_2, raycast_hit_2} : {raycast_valid, raycast_hit};
    logic [31:0] display = btnl ? 
    (btnu ? {raycast_intersection_2[2], raycast_sq_distance_2} : {raycast_intersection_2[0], raycast_intersection_2[1]})
    : (btnu ? {raycast_intersection[2], raycast_sq_distance} : {raycast_intersection[0], raycast_intersection[1]});

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

    seven_segment_controller ssc (
        .clk_in(clk_50mhz),
        .rst_in(rst),
        .val_in(display),
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