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
  assign led[2] = rast_busy;

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
      .light_read_addr(),
      .geometry_read_addr(rast_tri_addr),
      .controller_busy(rast_busy),
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
  logic rast_busy;
  TriangleAddr rast_tri_addr;

  logic controller_tri_valid;
  Triangle controller_tri;

  logic step_mem_ready;
  assign step_mem_ready = mem_ready && (!step_by_step || next_step);

  logic pause_rast_controller;

  rasterization_controller controller (
      .clk(sys_clk),
      .rst(sys_rst),
      .execInst_valid(execInst_valid),
      .execInst(execInst),
      .mem_ready(step_mem_ready),
      .pause(pause_rast_controller),
      .cur_triangle(cur_geo),
      .busy(rast_busy),
      .cur_tri_addr(rast_tri_addr),
      .next_triangle_valid(controller_tri_valid),
      .next_triangle(controller_tri)
  );


  tri_3d controller_tri_3d;

  assign controller_tri_3d[0][0] = controller_tri.x1;
  assign controller_tri_3d[0][1] = controller_tri.y1;
  assign controller_tri_3d[0][2] = controller_tri.z1;
  assign controller_tri_3d[1][0] = controller_tri.x2;
  assign controller_tri_3d[1][1] = controller_tri.y2;
  assign controller_tri_3d[1][2] = controller_tri.z2;
  assign controller_tri_3d[2][0] = controller_tri.x3;
  assign controller_tri_3d[2][1] = controller_tri.y3;
  assign controller_tri_3d[2][2] = controller_tri.z3;

  assign led[15] = controller_tri_valid;
  assign led[14] = rast_tri_was_valid;

  logic sys_rst, sys_clk, clk_div_100mhz, clk_div_65mhz, pix_clk;

  //vga module generation signals:
  logic [`FRAME_COORD_BITS-1:0] hcount_pix_clk, hcount, vcount_pix_clk, vcount;

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

  tri_3d cam_tri;
  tri_2d rast_tri, tfill_in;

  vec3_i16 out_test_pt, rast_pt;

  logic screen_pt_valid, ndc_pt_valid, rast_tri_valid;

  vec2_f16 screen_pt, ndc_pt;

  localparam ONE = 16'h3C00;

  localparam FLOAT_FRAME_WIDTH = 16'h6000;  // 512
  localparam FLOAT_FRAME_HEIGHT = 16'h5E00;  // 384

  view camera;
  logic [31:0] seven_seg_val;


  enum {
    Idle,  // while !rast_busy
    RequestingTriangle,  // set pause low (1 cycle)
    WaitingForController,  // waiting for controller_tri_valid
    CalculatingTriangle,  // waiting for rast_tri_valid
    TriangleFilling  // while <-> hcount, vcount
  } rast_state;

  assign led[12:8] = rast_state;

  triangle_3d_to_2d t23 (  // 63 stages
      .clk(sys_clk),
      .rst(sys_rst),
      .camera(camera),
      .input_valid(controller_tri_valid),
      .triangle_3d(controller_tri_3d),
      .triangle_2d(rast_tri),
      .triangle_2d_valid(rast_tri_valid)
  );

  seven_segment_controller mssc (
      .clk_in (sys_clk),
      .rst_in (sys_rst),
      .val_in (seven_seg_val),
      .cat_out({cag, caf, cae, cad, cac, cab, caa}),
      .an_out (an)
  );

  assign seven_seg_val = {
    controller_tri.x3,
    controller_tri.col[15:14],
    controller_tri.col[1:0],
    3'b0,
    pc_debug,
    3'b0,
    rast_tri_addr
  };

  localparam TEN = 'h4900;
  localparam SEVEN_FIVE = 'h4780;  // 7.5
  localparam HUNDRED = 'h5640;

  logic [`PBRAM_ADDR_BITS-1:0] pixel_addr, pixel_addr_pix_clk;

  assign pixel_addr = `FRAME_WIDTH * vcount + hcount;
  assign pixel_addr_pix_clk = `FRAME_WIDTH * (vcount_pix_clk >> 1) + (hcount_pix_clk >> 1);

  assign pause_rast_controller = rast_state != RequestingTriangle;

  always_ff @(posedge sys_clk) begin
    if (sys_rst) begin
      cam_tri[0][0] <= 'hbc00;  // -1
      cam_tri[0][1] <= 'hbc00;  // -1
      cam_tri[0][2] <= 'hc000;  // -2

      cam_tri[1][0] <= 'h3c00;  // 1
      cam_tri[1][1] <= 'hbe00;  // -1.5
      cam_tri[1][2] <= 'hc000;  // -2

      cam_tri[2][0] <= 'h3c00;  // 1
      cam_tri[2][1] <= 'h3c00;  // 1
      cam_tri[2][2] <= 'hc000;  // -2

      camera.near_clip <= ONE;

      camera.canvas_dimensions[0] <= TEN;
      camera.canvas_dimensions[1] <= SEVEN_FIVE;

      camera.image_dimensions[0] <= FLOAT_FRAME_WIDTH;
      camera.image_dimensions[1] <= FLOAT_FRAME_HEIGHT;

      rast_state <= Idle;
      hcount <= 0;
      vcount <= 0;
      rast_tri_was_valid <= 0;

    end else begin
      rast_tri_was_valid <= rast_tri_valid | rast_tri_valid;

      if (rast_state == Idle) begin
        if (rast_busy) begin
          rast_state <= RequestingTriangle;
        end
      end else if (rast_state == RequestingTriangle) begin
        rast_state <= WaitingForController;
      end else if (rast_state == WaitingForController) begin
        if (controller_tri_valid) begin
          rast_state <= CalculatingTriangle;
        end
      end else if (rast_state == CalculatingTriangle) begin
        if (rast_tri_valid) begin
          rast_state <= TriangleFilling;
        end
      end else if (rast_state == TriangleFilling) begin
        if ((hcount == `FRAME_WIDTH - 1) && (vcount == `FRAME_HEIGHT - 1)) begin
          rast_state <= Idle;
          hcount <= 0;
          vcount <= 0;
        end else begin
          if (hcount == `FRAME_WIDTH - 1) begin
            hcount <= 0;
            vcount <= vcount + 1;
          end else begin
            hcount <= hcount + 1;
          end
        end
      end

    end
  end

  assign pixel_write_enable = sw[15] | is_within;

  logic is_within, rast_tri_was_valid, is_within_valid;

  triangle_2d_fill tfill (  // 3
      .rst(sys_rst),
      .clk(sys_clk),
      .hcount(hcount),
      .triangle_valid(rast_tri_valid),
      .vcount(vcount),
      .output_valid(is_within_valid),
      .triangle(rast_tri),
      .is_within(is_within)
  );

  logic [`PADDED_COLOR_WIDTH-1:0] triangle_color_piped;

  pipe #(
      .LENGTH(67),  // 53 (proj+ndc+rast) + 4 (fill)
      .WIDTH(`PADDED_COLOR_WIDTH)
  ) triangle_color_pipe (
      .clk(sys_clk),
      .rst(sys_rst),
      .in (controller_tri.col),
      .out(triangle_color_piped)
  );

  assign pixel_write = sw[15] ? 16'b0 : triangle_color_piped;
  assign vga_pixel = pixel_read_pix_clk;

  assign vga_r = ~blank ? vga_pixel[11:8] : 0;
  assign vga_g = ~blank ? vga_pixel[7:4] : 0;
  assign vga_b = ~blank ? vga_pixel[3:0] : 0;

  assign vga_hs = ~hsync;
  assign vga_vs = ~vsync;

endmodule
`default_nettype wire
