`default_nettype none

module triangle_3d_project (
    input wire clk,
    input wire rst,
    input wire signed cam_near_clip,
    // input wire signed cam_z,
    input wire [2:0][2:0][10:0] triangle_3d,
    output logic [2:0][2:0][10:0] triangle_2d
);

  logic [23:0] t2d_v1_x_p, t2d_v1_y_p, t2d_v2_x_p, t2d_v2_y_p, t2d_v3_x_p, t2d_v3_y_p;
  logic signed [11:0]
      t3d_v1_x, t3d_v1_y, t3d_v1_z, t3d_v2_x, t3d_v2_y, t3d_v2_z, t3d_v3_x, t3d_v3_y, t3d_v3_z;
  logic [10:0]
      t2d_v1_x, t2d_v1_y, t2d_v1_z, t2d_v2_x, t2d_v2_y, t2d_v2_z, t2d_v3_x, t2d_v3_y, t2d_v3_z;

  assign t3d_v1_x = $signed({1'b0, triangle_2d[0][0]});
  assign t3d_v1_y = $signed({1'b0, triangle_2d[0][1]});
  assign t3d_v1_z = $signed({1'b0, triangle_2d[0][2]});

  assign t3d_v2_x = $signed({1'b0, triangle_2d[1][0]});
  assign t3d_v2_y = $signed({1'b0, triangle_2d[1][1]});
  assign t3d_v2_z = $signed({1'b0, triangle_2d[1][2]});

  assign t3d_v3_x = $signed({1'b0, triangle_2d[2][0]});
  assign t3d_v3_y = $signed({1'b0, triangle_2d[2][1]});
  assign t3d_v3_z = $signed({1'b0, triangle_2d[2][2]});

  assign triangle_2d[0][0] = t2d_v1_x;
  assign triangle_2d[0][1] = t2d_v1_y;
  assign triangle_2d[0][2] = t2d_v1_z;

  assign triangle_2d[1][0] = t2d_v2_x;
  assign triangle_2d[1][1] = t2d_v2_y;
  assign triangle_2d[1][2] = t2d_v2_z;

  assign triangle_2d[2][0] = t2d_v3_x;
  assign triangle_2d[2][1] = t2d_v3_y;
  assign triangle_2d[2][2] = t2d_v3_z;

  float_multiply t3d_v1_x_mul (
      .aclk                (aclk),                  // input wire aclk
      .s_axis_a_tvalid     (s_axis_a_tvalid),       // input wire s_axis_a_tvalid
      .s_axis_a_tdata      (s_axis_a_tdata),        // input wire [15 : 0] s_axis_a_tdata
      .s_axis_b_tvalid     (s_axis_b_tvalid),       // input wire s_axis_b_tvalid
      .s_axis_b_tdata      (s_axis_b_tdata),        // input wire [15 : 0] s_axis_b_tdata
      .m_axis_result_tvalid(m_axis_result_tvalid),  // output wire m_axis_result_tvalid
      .m_axis_result_tdata (m_axis_result_tdata)    // output wire [15 : 0] m_axis_result_tdata
  );


  always_ff @(posedge clk) begin
    t2d_v1_x_p <= t3d_v1_x * cam_near_clip * -1'd1;
    t2d_v1_y_p <= t3d_v1_y * cam_near_clip * -1'd1;

    t2d_v2_x_p <= t3d_v2_x * cam_near_clip * -1'd1;
    t2d_v2_y_p <= t3d_v2_y * cam_near_clip * -1'd1;

    t2d_v3_x_p <= t3d_v3_x * cam_near_clip * -1'd1;
    t2d_v3_y_p <= t3d_v3_y * cam_near_clip * -1'd1;

    // t2d_v1_x <= t2d_v1_x_p 





  end

endmodule



`default_nettype wire
