`default_nettype none
import types::*;

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
    output logic [3:0] vga_r,
    vga_g,
    vga_b,
    output logic vga_hs,
    vga_vs,
    output wire [15:0] led

);

  logic sys_clk, sys_rst, clk_200mhz, clk_65mhz;
  assign sys_rst = btnc;
  logic [31:0] seven_seg_val;

  clk_divider clk_div (
      .reset(sys_rst),
      .clk_in_100(clk_100mhz),
      .clk_out_200(clk_200mhz),
      .clk_out_65(clk_65mhz)
  );

  assign sys_clk = clk_200mhz;

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

  // vec3_f16 cam_tri;
  tri_3d cam_tri;
  tri_2d rast_tri;

  vec3_i16 out_test_pt, rast_pt, t_fill_in;

  logic screen_pt_valid, ndc_pt_valid, rast_tri_valid;

  vec2_f16 screen_pt, ndc_pt;

  localparam ONE = 16'h3C00;
  localparam TWO = 16'h4000;
  localparam FIVE_TWELVE = 16'h6000;  // 512

  localparam TEN_TWENTY_FOUR = 16'h6400; // 1024
  localparam SEVEN_SIXTY_EIGHT = 16'h6200; // 768

  view camera;

  triangle_3d_to_2d t23 (
    .clk(sys_clk),
    .rst(sys_rst),
    .camera(camera),
    .input_valid(1'b1),
    .triangle_3d(cam_tri),
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

  logic [2:0] vert_setting, coord_setting;
  logic [1:0] vert_index, coord_index;
  logic displaying_t3d;

  assign coord_setting = sw[2:0];
  assign vert_setting = sw[5:3]; 
  assign displaying_t3d = sw[6];

  assign led[2:0] = coord_setting;
  assign led[5:3] = vert_setting;
  assign led[6] = displaying_t3d;

  always_comb begin
    if (sys_rst) begin
      seven_seg_val = 0;
      coord_index = 0;
      vert_index = 0;
    end else begin

      if (vert_setting == 'b001) begin
        vert_index = 2'd0;
      end else if (vert_setting == 'b010) begin
        vert_index = 2'd1;
      end else if (vert_setting == 'b100) begin
        vert_index = 2'd2;
      end else begin
        vert_index = 2'd0;
      end

      if (coord_setting == 'b001) begin
        coord_index = 2'd0;
      end else if (coord_setting == 'b010) begin
        coord_index = 2'd1;
      end else if (coord_setting == 'b100) begin
        coord_index = 2'd2;
      end else begin
        coord_index = 2'd0;
      end

      seven_seg_val = displaying_t3d ? cam_tri[vert_index][coord_index] : rast_tri[vert_index][coord_index];

    end
  end

  logic sub_small_valid, sub_big_valid, add_small_valid, add_big_valid;
  f16 sub_small_out, sub_big_out, add_small_out, add_big_out;

  localparam TEN = 'h4900;
  localparam HUNDRED = 'h5640;

  float_add_sub f_sub_small (
      .aclk(sys_clk),  // input wire aclk
      .s_axis_a_tvalid(p_btnl),  // input wire s_axis_a_tvalid
      .s_axis_b_tvalid(p_btnl),  // input wire s_axis_b_tvalid
      .s_axis_operation_tvalid(p_btnl),  // input wire s_axis_operation_tvalid
      .s_axis_a_tdata(cam_tri[vert_index][coord_index]),  // input wire [15 : 0] s_axis_a_tdata
      .s_axis_b_tdata(TEN),  // input wire [15 : 0] s_axis_b_tdata
      .s_axis_operation_tdata(8'b00000001),  // input wire [7 : 0] s_axis_operation_tdata
      .m_axis_result_tvalid(sub_small_valid),  // output wire m_axis_result_tvalid
      .m_axis_result_tdata(sub_small_out)  // output wire [15 : 0] m_axis_result_tdata
  );

  float_add_sub f_sub_big (
      .aclk(sys_clk),  // input wire aclk
      .s_axis_a_tvalid(p_btnd),  // input wire s_axis_a_tvalid
      .s_axis_b_tvalid(p_btnd),  // input wire s_axis_b_tvalid
      .s_axis_operation_tvalid(p_btnd),  // input wire s_axis_operation_tvalid
      .s_axis_a_tdata(cam_tri[vert_index][coord_index]),  // input wire [15 : 0] s_axis_a_tdata
      .s_axis_b_tdata(HUNDRED),  // input wire [15 : 0] s_axis_b_tdata
      .s_axis_operation_tdata(8'b00000001),  // input wire [7 : 0] s_axis_operation_tdata
      .m_axis_result_tvalid(sub_big_valid),  // output wire m_axis_result_tvalid
      .m_axis_result_tdata(sub_big_out)  // output wire [15 : 0] m_axis_result_tdata
  );

  float_add_sub f_add_small (
      .aclk(sys_clk),  // input wire aclk
      .s_axis_a_tvalid(p_btnr),  // input wire s_axis_a_tvalid
      .s_axis_b_tvalid(p_btnr),  // input wire s_axis_b_tvalid
      .s_axis_operation_tvalid(p_btnr),  // input wire s_axis_operation_tvalid
      .s_axis_a_tdata(cam_tri[vert_index][coord_index]),  // input wire [15 : 0] s_axis_a_tdata
      .s_axis_b_tdata(TEN),  // input wire [15 : 0] s_axis_b_tdata
      .s_axis_operation_tdata(8'b0),  // input wire [7 : 0] s_axis_operation_tdata
      .m_axis_result_tvalid(add_small_valid),  // output wire m_axis_result_tvalid
      .m_axis_result_tdata(add_small_out)  // output wire [15 : 0] m_axis_result_tdata
  );

  float_add_sub f_add_big (
      .aclk(sys_clk),  // input wire aclk
      .s_axis_a_tvalid(p_btnu),  // input wire s_axis_a_tvalid
      .s_axis_b_tvalid(p_btnu),  // input wire s_axis_b_tvalid
      .s_axis_operation_tvalid(p_btnu),  // input wire s_axis_operation_tvalid
      .s_axis_a_tdata(cam_tri[vert_index][coord_index]),  // input wire [15 : 0] s_axis_a_tdata
      .s_axis_b_tdata(HUNDRED),  // input wire [15 : 0] s_axis_b_tdata
      .s_axis_operation_tdata(8'b0),  // input wire [7 : 0] s_axis_operation_tdata
      .m_axis_result_tvalid(add_big_valid),  // output wire m_axis_result_tvalid
      .m_axis_result_tdata(add_big_out)  // output wire [15 : 0] m_axis_result_tdata
  );


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

      camera.canvas_dimensions[0] <= TWO;
      camera.canvas_dimensions[1] <= TWO;

      camera.image_dimensions[0] <= TEN_TWENTY_FOUR;
      camera.image_dimensions[1] <= SEVEN_SIXTY_EIGHT;

    end else begin
      if (sub_small_valid) begin
        cam_tri[vert_index][coord_index] <= sub_small_out;
      end else if (sub_big_valid) begin
        cam_tri[vert_index][coord_index] <= sub_big_out;
      end else if (add_small_valid) begin
        cam_tri[vert_index][coord_index] <= add_small_out;
      end else if (add_big_valid) begin
        cam_tri[vert_index][coord_index] <= add_big_out;
      end
    end
  end

endmodule
`default_nettype wire
