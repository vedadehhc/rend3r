module triangle_normal (
    input wire clk,
    input wire rst,
    input wire input_valid,
    input tri_3d triangle,
    output vec3_f16 normal,
    output wire normal_valid
);

  f16 u_x, u_y, u_z, v_x, v_y, v_z, n_x, n_y, n_z;
  vec3_f16 p1, p2, p3, u, v;
  logic u_valid, v_valid, u_v_valid, n_x_valid, n_y_valid, n_z_valid;

  assign p1 = triangle[0];
  assign p2 = triangle[1];
  assign p3 = triangle[2];

  assign u_x = u[0];
  assign u_y = u[1];
  assign u_z = u[2];

  assign v_x = v[0];
  assign v_y = v[1];
  assign v_z = v[2];

  assign normal[0] = n_x;
  assign normal[1] = n_y;
  assign normal[2] = n_z;

  assign normal_valid = n_x_valid && n_y_valid && n_z_valid;
  assign u_v_valid = u_valid && v_valid;

  vertex_add_sub u_sub (
      .clk(clk),
      .rst(rst),
      .input_valid(input_valid),
      .v_a(p2),
      .v_b(p1),
      .operation(8'b00000001),
      .v_out(u),
      .output_valid(u_valid)
  );

  vertex_add_sub v_sub (
      .clk(clk),
      .rst(rst),
      .input_valid(input_valid),
      .v_a(p3),
      .v_b(p1),
      .operation(8'b00000001),
      .v_out(v),
      .output_valid(v_valid)
  );

  multiply_sub x_ms (
      .clk(clk),
      .rst(rst),
      .n1(u_y),
      .n2(v_z),
      .n3(u_z),
      .n4(v_y),
      .input_valid(u_v_valid),
      .out(n_x),
      .output_valid(n_x_valid)
  );

  multiply_sub y_ms (
      .clk(clk),
      .rst(rst),
      .n1(u_z),
      .n2(v_x),
      .n3(u_x),
      .n4(v_z),
      .input_valid(u_v_valid),
      .out(n_y),
      .output_valid(n_y_valid)
  );

  multiply_sub z_ms (
      .clk(clk),
      .rst(rst),
      .n1(u_x),
      .n2(v_y),
      .n3(u_y),
      .n4(v_x),
      .input_valid(u_v_valid),
      .out(n_z),
      .output_valid(n_z_valid)
  );

endmodule


module multiply_sub (
    input wire clk,
    input wire rst,
    input wire f16 n1,
    input wire f16 n2,
    input wire f16 n3,
    input wire f16 n4,
    input wire input_valid,
    output f16 out,
    output wire output_valid
);

  f16 mul_a_out, mul_b_out;
  logic mul_a_valid, mul_b_valid;

  float_multiply mul_a (
      .aclk                (clk),          // input wire aclk
      .s_axis_a_tvalid     (input_valid),  // input wire s_axis_a_tvalid
      .s_axis_b_tvalid     (input_valid),  // input wire s_axis_b_tvalid
      .s_axis_a_tdata      (n1),           // input wire [15 : 0] s_axis_a_tdata
      .s_axis_b_tdata      (n2),           // input wire [15 : 0] s_axis_b_tdata
      .m_axis_result_tvalid(mul_a_valid),  // output wire m_axis_result_tvalid
      .m_axis_result_tdata (mul_a_out)     // output wire [15 : 0] m_axis_result_tdata
  );

  float_multiply mul_a (
      .aclk                (clk),          // input wire aclk
      .s_axis_a_tvalid     (input_valid),  // input wire s_axis_a_tvalid
      .s_axis_b_tvalid     (input_valid),  // input wire s_axis_b_tvalid
      .s_axis_a_tdata      (n3),           // input wire [15 : 0] s_axis_a_tdata
      .s_axis_b_tdata      (n4),           // input wire [15 : 0] s_axis_b_tdata
      .m_axis_result_tvalid(mul_b_valid),  // output wire m_axis_result_tvalid
      .m_axis_result_tdata (mul_b_out)     // output wire [15 : 0] m_axis_result_tdata
  );

  float_add_sub f_sub (
      .aclk(clk),  // input wire aclk
      .s_axis_a_tvalid(mul_a_valid),  // input wire s_axis_a_tvalid
      .s_axis_b_tvalid(mul_b_valid),  // input wire s_axis_b_tvalid
      .s_axis_operation_tvalid(1'b1),  // input wire s_axis_operation_tvalid
      .s_axis_a_tdata(mul_a_out),  // input wire [15 : 0] s_axis_a_tdata
      .s_axis_b_tdata(mul_b_out),  // input wire [15 : 0] s_axis_b_tdata
      .s_axis_operation_tdata(8'b00000001),  // input wire [7 : 0] s_axis_operation_tdata
      .m_axis_result_tvalid(output_valid),  // output wire m_axis_result_tvalid
      .m_axis_result_tdata(out)  // output wire [15 : 0] m_axis_result_tdata
  );


endmodule

// Begin Function CalculateSurfaceNormal (Input Triangle) Returns Vector

// 	Set Vector U to (Triangle.p2 minus Triangle.p1)
// 	Set Vector V to (Triangle.p3 minus Triangle.p1)

// 	Set Normal.x to (multiply U.y by V.z) minus (multiply U.z by V.y)
// 	Set Normal.y to (multiply U.z by V.x) minus (multiply U.x by V.z)
// 	Set Normal.z to (multiply U.x by V.y) minus (multiply U.y by V.x)

// 	Returning Normal

// End Function
