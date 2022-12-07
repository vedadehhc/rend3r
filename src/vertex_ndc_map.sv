// `default_nettype none

import types::*;

module vertex_ndc_map (
    input wire clk,
    input wire rst,
    input wire vec2_f16 screen_pt,
    input wire vec2_f16 canvas_dimensions,
    input wire input_valid,
    output vec2_f16 ndc_pt,
    output logic ndc_pt_valid
);

  f16 canvas_width, canvas_height, ndc_x, ndc_y, screen_x, screen_y, map_x_out, map_y_out;

  logic map_x_valid, map_y_valid;

  assign canvas_width = canvas_dimensions[0];
  assign canvas_height = canvas_dimensions[1];

  assign screen_x = screen_pt[0];
  assign screen_y = screen_pt[1];

  assign ndc_pt_valid = map_x_valid && map_y_valid;

  assign ndc_pt[0] = ndc_x;
  assign ndc_pt[1] = ndc_y;

  assign ndc_x = map_x_out;
  assign ndc_y = map_y_out;

  coord_map map_x (
      .clk(clk),
      .rst(rst),
      .input_valid(input_valid),
      .coord(screen_x),
      .dimension_extent(canvas_width),
      .ndc_coord(map_x_out),
      .output_valid(map_x_valid)
  );

  coord_map map_y (
      .clk(clk),
      .rst(rst),
      .input_valid(input_valid),
      .coord(screen_y),
      .dimension_extent(canvas_height),
      .ndc_coord(map_y_out),
      .output_valid(map_y_valid)
  );

endmodule

module coord_map (
    input wire clk,
    input wire rst,
    input wire input_valid,
    input f16 coord,
    input f16 dimension_extent,
    output f16 ndc_coord,
    output logic output_valid
);

  f16 div_out, add_out;
  logic div_valid, add_valid;

  localparam ONE_HALF = 16'h3800;  // https://evanw.github.io/float-toy/

  assign ndc_coord = add_out;
  assign output_valid = add_valid;

  float_divide f_div (
      .aclk                (clk),               // input wire aclk
      .s_axis_a_tvalid     (input_valid),       // input wire s_axis_a_tvalid
      .s_axis_b_tvalid     (input_valid),       // input wire s_axis_b_tvalid
      .s_axis_a_tdata      (coord),             // input wire [15 : 0] s_axis_a_tdata
      .s_axis_b_tdata      (dimension_extent),  // input wire [15 : 0] s_axis_b_tdata
      .m_axis_result_tvalid(div_valid),         // output wire m_axis_result_tvalid
      .m_axis_result_tdata (div_out)            // output wire [15 : 0] m_axis_result_tdata
  );

  float_add_sub f_add (
      .aclk(clk),  // input wire aclk
      .s_axis_a_tvalid(div_valid),  // input wire s_axis_a_tvalid
      .s_axis_a_tdata(div_out),  // input wire [15 : 0] s_axis_a_tdata
      .s_axis_b_tvalid(1'b1),  // input wire s_axis_b_tvalid
      .s_axis_b_tdata(ONE_HALF),  // input wire [15 : 0] s_axis_b_tdata
      .s_axis_operation_tvalid(1'b1),  // input wire s_axis_operation_tvalid
      .s_axis_operation_tdata(8'b0),  // input wire [7 : 0] s_axis_operation_tdata
      .m_axis_result_tvalid(add_valid),  // output wire m_axis_result_tvalid
      .m_axis_result_tdata(add_out)  // output wire [15 : 0] m_axis_result_tdata
  );

endmodule
// `default_nettype wire
