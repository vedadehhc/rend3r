`default_nettype none
// 
`timescale 1ns / 1ps


// to change res, need to change here, change in vga, change decimal vals for canvas
`define FRAME_WIDTH 512
`define FRAME_HEIGHT 384

`define PADDED_COLOR_WIDTH 16
`define COLOR_WIDTH 12
`define FRAME_COORD_BITS 16
`define PBRAM_ADDR_BITS 18

import types::*;
import proctypes::*;

module top_level (
    input wire clk_100mhz,
    input wire [15:0] sw,
    input wire btnc,
    input wire btnu,
    input wire btnl,
    input wire btnr,
    input wire btnd,
    output logic [7:0] an,
    output logic caa,
    cab,
    cac,
    cad,
    cae,
    caf,
    cag,

    output wire [15:0] led,
    output logic [3:0] vga_r,
    vga_g,
    vga_b,
    output logic vga_hs,
    vga_vs

);

  logic step_by_step = sw[0];
  logic next_step = p_btnu;

  assign led[0] = c_btnu;
  assign led[1] = mem_ready;
  assign led[2] = ray_busy;


  logic execInst_valid;
  DecodedInst execInst;
  logic mem_ready;
  Camera cur_camera;
  Light cur_light;
  logic [GEOMETRY_WIDTH-1:0] cur_geo;
  InstructionAddr pc_debug;
  iprocessor processor (
      .clk_100mhz(sys_clk),
      .rst(sys_rst),
      .step_mode(step_by_step),
      .next_step(next_step),
      .light_read_addr(ray_light_addr),
      .geometry_read_addr(ray_shape_addr),
      .controller_busy(ray_busy),
      .execInst_valid(execInst_valid),
      .execInst(execInst),
      .mem_ready(mem_ready),
      .cur_camera(cur_camera),
      .cur_light(cur_light),
      .cur_geo(cur_geo),
      .pc_debug(pc_debug)
  );

  // rasterization controller 
  // should iterate through all triangles and pass to rasterizer
  logic ray_busy;
  ShapeAddr ray_shape_addr;
  LightAddr ray_light_addr;

  logic ray_valid_out;
  assign pixel_write_enable = ray_valid_out;

  ScreenX ray_pixel_x;
  ScreenY ray_pixel_y;
  assign hcount = ray_pixel_x;
  assign vcount = ray_pixel_y;

  logic [`PADDED_COLOR_WIDTH-1:0] ray_pixel_out;
  assign pixel_write = ray_pixel_out;

  logic step_mem_ready;
  // assign step_mem_ready = mem_ready && (!step_by_step || next_step);

  raytracing_controller controller (
      .clk(sys_clk),
      .rst(sys_rst),
      .execInst_valid(execInst_valid),
      .execInst(execInst),
      .mem_ready(mem_ready),
      .cur_shape(cur_geo),
      .cur_light(cur_light),
      .cur_camera(cur_camera),
      .busy(ray_busy),
      .cur_shape_addr(ray_shape_addr),
      .cur_light_addr(ray_light_addr),
      .valid_out(ray_valid_out),
      .pixel_x_out(ray_pixel_x),
      .pixel_y_out(ray_pixel_y),
      .pixel_value(ray_pixel_out)
  );

  assign led[15] = ray_valid_out;


  logic sys_rst, sys_clk, clk_div_100mhz, clk_div_65mhz, pix_clk;

  //vga module generation signals:
  logic [`FRAME_COORD_BITS-1:0]
      hcount_pix_clk,
      hcount, vcount_pix_clk, vcount;

  logic hsync, vsync, blank, vga_pause;  //control signals for vga

  assign sys_rst = btnc;

  clk_divider clk_div (
      .reset(sys_rst),
      .clk_in_100(clk_100mhz),
      .clk_out_100(clk_div_100mhz),
      .clk_out_65(clk_div_65mhz)
  );

  assign sys_clk = clk_div_100mhz;
  assign pix_clk = clk_div_65mhz;

  vga vga_gen (
      .rst(sys_rst),
      .pixel_clk_in(pix_clk),
      .hcount_out(hcount_pix_clk),
      .vcount_out(vcount_pix_clk),
      .hsync_out(hsync),
      .vsync_out(vsync),
      .blank_out(blank)
  );

  logic current_inner_pixel_read_buffer_pix_clk;
  logic [`COLOR_WIDTH-1:0] vga_pixel;

  button bu (
      .clk(sys_clk),
      .rst(sys_rst),
      .raw_in(btnu),
      .pulse_out(p_btnu),
      .clean_out(c_btnu)
  );
  button bd (
      .clk(sys_clk),
      .rst(sys_rst),
      .raw_in(btnd),
      .pulse_out(p_btnd),
      .clean_out(c_btnd)
  );
  button bl (
      .clk(sys_clk),
      .rst(sys_rst),
      .raw_in(btnl),
      .pulse_out(p_btnl),
      .clean_out(c_btnl)
  );
  button br (
      .clk(sys_clk),
      .rst(sys_rst),
      .raw_in(btnr),
      .pulse_out(p_btnr),
      .clean_out(c_btnr)
  );

  logic p_btnu, p_btnd, p_btnl, p_btnr, p_btnc;
  logic c_btnu, c_btnd, c_btnl, c_btnr, c_btnc;

  logic pixel_write_enable;
  logic [`PADDED_COLOR_WIDTH-1:0] pixel_write, pixel_read_pix_clk;

  pixel_bram pix_bram (
      .clka(sys_clk),  // input wire clka
      .wea(pixel_write_enable),  // input wire [0 : 0] wea
      .addra(pixel_addr),  // input wire [17 : 0] addra
      .dina(pixel_write),  // input wire [15 : 0] dina
      .clkb(pix_clk),  // input wire clkb
      .addrb(pixel_addr_pix_clk),  // input wire [17 : 0] addrb
      .doutb(pixel_read_pix_clk)  // output wire [15 : 0] doutb
  );

  logic [31:0] seven_seg_val;
  assign seven_seg_val = {ray_pixel_out, ray_pixel_y[7:0], ray_pixel_x[3:0], pc_debug};// displaying_t3d ? cam_tri[vert_index][coord_index] : rast_tri[vert_index][coord_index];


  seven_segment_controller mssc (
      .clk_in (sys_clk),
      .rst_in (sys_rst),
      .val_in (seven_seg_val),
      .cat_out({cag, caf, cae, cad, cac, cab, caa}),
      .an_out (an)
  );

  logic [`PBRAM_ADDR_BITS-1:0] pixel_addr, pixel_addr_pix_clk;

  assign pixel_addr = `FRAME_WIDTH * vcount + hcount;
  assign pixel_addr_pix_clk = `FRAME_WIDTH * (vcount_pix_clk >> 1) + (hcount_pix_clk >> 1);

  assign vga_pixel = pixel_read_pix_clk;

  assign vga_r  = ~blank ? vga_pixel[11:8] : 0;
  assign vga_g  = ~blank ? vga_pixel[7:4] : 0;
  assign vga_b  = ~blank ? vga_pixel[3:0] : 0;

  assign vga_hs = ~hsync;
  assign vga_vs = ~vsync;

endmodule
`default_nettype wire
