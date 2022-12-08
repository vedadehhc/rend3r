`default_nettype none
import types::*;

module vertex_rasterize (
    input wire clk,
    input wire rst,
    input wire input_valid,
    input wire vec2_f16 ndc_pt,
    input wire vec3_f16 vertex_3d,
    input wire vec2_f16 image_dimensions,
    output vec3_i13 rast_pt,  // third element of rast_pt is z distance
    output logic rast_pt_valid
);

  localparam ONE = 16'h3C00;  // https://evanw.github.io/float-toy/

  f16 ndc_x, ndc_x_delayed, ndc_y, z_dist, sub_out, image_width, image_height;
  logic sub_valid, input_valid_delayed, rast_x_valid, rast_y_valid, rast_valid_delayed, fx13_valid;
  fx13 fx13_out;

  assign ndc_x = ndc_pt[0];
  assign ndc_y = ndc_pt[1];
  assign z_dist = vertex_3d[2];  //{1'b1, vertex_3d[2][14:0]};  // negative

  assign image_width = image_dimensions[0];
  assign image_height = image_dimensions[1];
  assign rast_pt_valid = rast_x_valid && rast_y_valid;

  assign rast_pt[0] = rast_x;
  assign rast_pt[1] = rast_y;
  assign rast_pt[2] = rast_z;

  i13 rast_x, rast_y, rast_z;

  pipe #(
      .LENGTH(6),
      .WIDTH(16)
  ) ndc_x_pipe (
      .clk(clk),
      .rst(rst),
      .in (ndc_x),
      .out(ndc_x_delayed)
  );

  pipe #(
      .LENGTH(6)
  ) input_valid_pipe (
      .clk(clk),
      .rst(rst),
      .in (input_valid),
      .out(input_valid_delayed)
  );

  float_add_sub f_sub (
      .aclk(clk),  // input wire aclk
      .s_axis_a_tvalid(1'b1),  // input wire s_axis_a_tvalid
      .s_axis_a_tdata(ONE),  // input wire [15 : 0] s_axis_a_tdata
      .s_axis_b_tvalid(input_valid),  // input wire s_axis_b_tvalid
      .s_axis_b_tdata(ndc_y),  // input wire [15 : 0] s_axis_b_tdata
      .s_axis_operation_tvalid(1'b1),  // input wire s_axis_operation_tvalid
      .s_axis_operation_tdata(8'b00000001),  // input wire [7 : 0] s_axis_operation_tdata
      .m_axis_result_tvalid(sub_valid),  // output wire m_axis_result_tvalid
      .m_axis_result_tdata(sub_out)  // output wire [15 : 0] m_axis_result_tdata
  );

  coord_rast x_rast (
      .clk(clk),
      .rst(rst),
      .input_valid(input_valid_delayed),
      .coord(ndc_x_delayed),
      .dimension_extent(image_width),
      .rast_coord(rast_x),
      .output_valid(rast_x_valid)
  );

  coord_rast y_rast (
      .clk(clk),
      .rst(rst),
      .input_valid(sub_valid),
      .coord(sub_out),
      .dimension_extent(image_height),
      .rast_coord(rast_y),
      .output_valid(rast_y_valid)
  );

  ila_rast ila (
      .clk(clk),
      .probe0(rast_x_valid),
      .probe1(input_valid_delayed),
      .probe2(ndc_x_delayed),
      .probe3(ndc_x),
      .probe4(rast_x)
  );

  float_to_fixed13 z_to_fx13 (
      .aclk                (clk),          // input wire aclk
      .s_axis_a_tvalid     (input_valid),  // input wire s_axis_a_tvalid
      .s_axis_a_tdata      ({~z_dist[15], z_dist[14:0]}),       // input wire [15 : 0] s_axis_a_tdata
      .m_axis_result_tvalid(fx13_valid),   // output wire m_axis_result_tvalid
      .m_axis_result_tdata (fx13_out)      // output wire [15 : 0] m_axis_result_tdata
  );

  always_ff @(posedge clk) begin
    if (rst) begin
      rast_z <= 0;
    end else begin
      if (fx13_valid) begin
        rast_z <= fx13_out; //fx13_out[12] ? -$signed({4'b0, fx13_out[11:0]}) : $signed({4'b0, fx13_out[11:0]});
      end
    end
  end

endmodule

module coord_rast (
    input wire clk,
    input wire rst,
    input wire input_valid,
    input wire f16 coord,
    input wire f16 dimension_extent,
    output i13 rast_coord,
    output logic output_valid
);

  f16  mul_out;
  fx13 fx13_out;
  logic mul_valid, fx13_valid;

  i13 coord_i13;  // $signed({1'b0, rast_coord[11:0]});


  assign output_valid = fx13_valid;
  //   assign coord_i13   = $signed({1'b0, fx13_out[11:0]});
  //   assign rast_coord  = fx13_out[12] ? -coord_i13 : coord_i13;
  assign rast_coord   = fx13_out;

  float_multiply f_mul (
      .aclk                (clk),               // input wire aclk
      .s_axis_a_tvalid     (input_valid),       // input wire s_axis_a_tvalid
      .s_axis_b_tvalid     (input_valid),       // input wire s_axis_b_tvalid
      .s_axis_a_tdata      (coord),             // input wire [15 : 0] s_axis_a_tdata
      .s_axis_b_tdata      (dimension_extent),  // input wire [15 : 0] s_axis_b_tdata
      .m_axis_result_tvalid(mul_valid),         // output wire m_axis_result_tvalid
      .m_axis_result_tdata (mul_out)            // output wire [15 : 0] m_axis_result_tdata
  );

  float_to_fixed13 f_to_fx13 (
      .aclk                (clk),         // input wire aclk
      .s_axis_a_tvalid     (mul_valid),   // input wire s_axis_a_tvalid
      .s_axis_a_tdata      (mul_out),     // input wire [15 : 0] s_axis_a_tdata
      .m_axis_result_tvalid(fx13_valid),  // output wire m_axis_result_tvalid
      .m_axis_result_tdata (fx13_out)     // output wire [15 : 0] m_axis_result_tdata
  );

endmodule

`default_nettype wire
