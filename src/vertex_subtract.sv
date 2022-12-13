`default_nettype none
import types::*;

module vertex_add_sub (
    input wire clk,
    input wire rst,
    input wire input_valid,
    input wire vec2_f16 v_a,
    input wire vec3_f16 v_b,
    input wire [7:0] operation,
    output vec2_f16 v_out,
    output wire output_valid
);

  f16 a1, a2, a3, b1, b2, b3, o1, o2, o3;
  logic o1_valid, o2_valid, o3_valid;

  assign a1 = v_a[0];
  assign a2 = v_a[1];
  assign a3 = v_a[2];

  assign b1 = v_b[0];
  assign b2 = v_b[1];
  assign b3 = v_b[2];

  assign v_out[0] = o1;
  assign v_out[1] = o2;
  assign v_out[2] = o3;

  assign output_valid = o1_valid && o2_valid && o3_valid;

  float_add_sub add_sub1 (
      .aclk(clk),  // input wire aclk
      .s_axis_a_tvalid(input_valid),  // input wire s_axis_a_tvalid
      .s_axis_b_tvalid(input_valid),  // input wire s_axis_b_tvalid
      .s_axis_operation_tvalid(input_valid),  // input wire s_axis_operation_tvalid
      .s_axis_a_tdata(a1),  // input wire [15 : 0] s_axis_a_tdata
      .s_axis_b_tdata(b1),  // input wire [15 : 0] s_axis_b_tdata
      .s_axis_operation_tdata(operation),  // input wire [7 : 0] s_axis_operation_tdata
      .m_axis_result_tvalid(o1),  // output wire m_axis_result_tvalid
      .m_axis_result_tdata(o1_valid)  // output wire [15 : 0] m_axis_result_tdata
  );

  float_add_sub add_sub2 (
      .aclk(clk),  // input wire aclk
      .s_axis_a_tvalid(input_valid),  // input wire s_axis_a_tvalid
      .s_axis_b_tvalid(input_valid),  // input wire s_axis_b_tvalid
      .s_axis_operation_tvalid(input_valid),  // input wire s_axis_operation_tvalid
      .s_axis_a_tdata(a2),  // input wire [15 : 0] s_axis_a_tdata
      .s_axis_b_tdata(b2),  // input wire [15 : 0] s_axis_b_tdata
      .s_axis_operation_tdata(operation),  // input wire [7 : 0] s_axis_operation_tdata
      .m_axis_result_tvalid(o2),  // output wire m_axis_result_tvalid
      .m_axis_result_tdata(o2_valid)  // output wire [15 : 0] m_axis_result_tdata
  );

  float_add_sub add_sub3 (
      .aclk(clk),  // input wire aclk
      .s_axis_a_tvalid(input_valid),  // input wire s_axis_a_tvalid
      .s_axis_b_tvalid(input_valid),  // input wire s_axis_b_tvalid
      .s_axis_operation_tvalid(input_valid),  // input wire s_axis_operation_tvalid
      .s_axis_a_tdata(a3),  // input wire [15 : 0] s_axis_a_tdata
      .s_axis_b_tdata(b3),  // input wire [15 : 0] s_axis_b_tdata
      .s_axis_operation_tdata(operation),  // input wire [7 : 0] s_axis_operation_tdata
      .m_axis_result_tvalid(o3),  // output wire m_axis_result_tvalid
      .m_axis_result_tdata(o3_valid)  // output wire [15 : 0] m_axis_result_tdata
  );

endmodule
`default_nettype wire