`default_nettype none
import types::*;

module old_top_level (
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
  assign sys_rst = sw[15];
  logic [31:0] seven_seg_val;

  clk_divider clk_div (
      .reset(sys_rst),
      .clk_in_100(clk_100mhz),
      .clk_out_200(clk_200mhz),
      .clk_out_65(clk_65mhz)
  );

  assign sys_clk = clk_200mhz;
  // assign pix_clk = clk_65mhz;

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
  button bc (
      .clk(sys_clk),
      .rst(sys_rst),
      .raw_in(btnc),
      .pulse_out(p_btnc),
      .clean_out(c_btnc)
  );

  logic p_btnu, p_btnd, p_btnl, p_btnr, p_btnc;
  logic c_btnu, c_btnd, c_btnl, c_btnr, c_btnc;

  vec3_f16 test_pt;
  vec3_i13 out_test_pt, rast_pt;

  logic screen_pt_valid, ndc_pt_valid, rast_pt_valid;

  vec2_f16 screen_pt, ndc_pt, canvas_dimensions, image_dimensions;

  localparam ONE = 16'h3C00;
  localparam TWO = 16'h4000;
  localparam FIVE_TWELVE = 16'h6000;  // 512

  f16 cam_near_clip;

  assign led[0] = screen_pt_valid;
  assign led[1] = ndc_pt_valid;
  assign led[2] = rast_pt_valid;

  vertex_project v_p (
      .clk(sys_clk),
      .rst(sys_rst),
      .cam_near_clip(cam_near_clip),
      .vertex_3d_valid(1'b1),
      .vertex_3d(test_pt),
      .screen_pt(screen_pt),
      .screen_pt_valid(screen_pt_valid)
  );

  vertex_ndc_map v_ndc_m (
      .clk(sys_clk),
      .rst(sys_rst),
      .screen_pt(screen_pt),
      .canvas_dimensions(canvas_dimensions),
      .input_valid(screen_pt_valid),
      .ndc_pt(ndc_pt),
      .ndc_pt_valid(ndc_pt_valid)
  );

  vertex_rasterize v_r (
      .clk(sys_clk),
      .rst(sys_rst),
      .input_valid(ndc_pt_valid),
      .ndc_pt(ndc_pt),
      .vertex_3d(test_pt),
      .image_dimensions(image_dimensions),
      .rast_pt(rast_pt),
      .rast_pt_valid(rast_pt_valid)
  );

  seven_segment_controller mssc (
      .clk_in (sys_clk),
      .rst_in (sys_rst),
      .val_in (seven_seg_val),
      .cat_out({cag, caf, cae, cad, cac, cab, caa}),
      .an_out (an)
  );

  logic [2:0] setting;
  logic [1:0] index;

  assign setting = {sw[2], sw[1], sw[0]};
  assign index   = {sw[4], sw[3]};

  always_comb begin
    if (sys_rst) begin
      seven_seg_val = 0;
    end else begin
      if (setting == 'b001) begin
        seven_seg_val = screen_pt[index];
      end else if (setting == 'b010) begin
        seven_seg_val = ndc_pt[index];
      end else if (setting == 'b100) begin
        seven_seg_val = rast_pt[index];
      end else begin
        seven_seg_val = 32'b1;
      end
    end
  end

  always_ff @(posedge sys_clk) begin
    if (sys_rst) begin
      test_pt[0] <= 'h4d00;  // 20
      test_pt[1] <= 'h4dc0;  // 23
      test_pt[2] <= 'hc000;  // -2

      canvas_dimensions[0] <= TWO;
      canvas_dimensions[1] <= TWO;

      image_dimensions[0] <= FIVE_TWELVE;
      image_dimensions[1] <= FIVE_TWELVE;

      cam_near_clip <= ONE;
    end else begin

    end
  end

endmodule
`default_nettype wire
