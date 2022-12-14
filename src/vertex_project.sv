`default_nettype none
import types::*;

module vertex_project ( // 21
    input wire clk,
    input wire rst,
    input wire f16 cam_near_clip,
    input wire input_valid,
    input wire vec3_f16 vertex_3d,
    output vec2_f16 screen_pt,
    output logic screen_pt_valid
);

  f16 v3d_x, v3d_y, v3d_z, zd_x_out, zd_y_out;
  f16 screen_x, screen_y;

  logic zd_x_valid, zd_y_valid;

  assign v3d_x = vertex_3d[0];
  assign v3d_y = vertex_3d[1];
  assign v3d_z = vertex_3d[2];

  assign screen_pt[0] = screen_x;
  assign screen_pt[1] = screen_y;
  // assign screen_pt[2] = out_z;

  assign screen_pt_valid = zd_x_valid && zd_y_valid;
  assign screen_x = zd_x_out;
  assign screen_y = zd_y_out;

  z_divide zd_x ( // 21
      .clk(clk),
      .rst(rst),
      .cam_near_clip(cam_near_clip),
      .coord(v3d_x),
      .z_coord(v3d_z),
      .input_valid(input_valid),
      .screen_coord(zd_x_out),
      .output_valid(zd_x_valid)
  );

  z_divide zd_y ( // 21
      .clk(clk),
      .rst(rst),
      .cam_near_clip(cam_near_clip),
      .coord(v3d_y),
      .z_coord(v3d_z),
      .input_valid(input_valid),
      .screen_coord(zd_y_out),
      .output_valid(zd_y_valid)
  );


endmodule

module z_divide ( // 21
    input  wire  clk,
    input  wire  rst,
    input  wire f16   cam_near_clip,
    input  wire f16   coord,
    input  wire f16   z_coord,
    input  wire  input_valid,
    output f16   screen_coord,
    output logic output_valid
);

  f16 div_out, mul_out, mul_in;
  logic div_valid, mul_valid;

  assign output_valid = mul_valid;
  assign screen_coord = mul_out;

  float_divide f_div ( // 15
      .aclk                (clk),                    // input wire aclk
      .s_axis_a_tvalid     (input_valid),                   // input wire s_axis_a_tvalid
      .s_axis_b_tvalid     (input_valid),                   // input wire s_axis_b_tvalid
      .s_axis_a_tdata      (coord),                  // input wire [15 : 0] s_axis_a_tdata
      .s_axis_b_tdata      ({~z_coord[15], z_coord[14:0]}),  // input wire [15 : 0] s_axis_b_tdata
      .m_axis_result_tvalid(div_valid),              // output wire m_axis_result_tvalid
      .m_axis_result_tdata (div_out)                 // output wire [15 : 0] m_axis_result_tdata
  );

  float_multiply f_mul ( // 6
      .aclk                (clk),           // input wire aclk
      .s_axis_a_tvalid     (div_valid),           // input wire s_axis_a_tvalid
      .s_axis_b_tvalid     (input_valid),           // input wire s_axis_b_tvalid
      .s_axis_a_tdata      (div_out),         // input wire [15 : 0] s_axis_a_tdata
      .s_axis_b_tdata      (cam_near_clip),  // input wire [15 : 0] s_axis_b_tdata
      .m_axis_result_tvalid(mul_valid),      // output wire m_axis_result_tvalid
      .m_axis_result_tdata (mul_out)         // output wire [15 : 0] m_axis_result_tdata
  );


endmodule
`default_nettype wire
