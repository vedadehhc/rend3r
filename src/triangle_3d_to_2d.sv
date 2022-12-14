`default_nettype none
import types::*;

module triangle_3d_to_2d ( // 63
    input wire clk,
    input wire rst,
    input wire view camera,
    input wire input_valid,
    input wire tri_3d triangle_3d,
    output tri_2d triangle_2d,
    output wire triangle_2d_valid
);

  logic v1_valid, v2_valid, v3_valid;

  assign triangle_2d_valid = v1_valid && v2_valid && v3_valid;

//   ila my_ila2 (
//     .clk(clk),
//     .probe0(v1_valid),
//     .probe1(v2_valid),
//     .probe2(v3_valid),
//     .probe3(16'b0),
//     .probe4(16'b0),
//     .probe5(16'b0),
//     .probe6(16'b0),
//     .probe7(1'b0)
//   );

  vertex_3d_to_2d v1 ( // 63
      .clk(clk),
      .rst(rst),
      .camera(camera),
      .input_valid(input_valid),
      .vertex_3d(triangle_3d[0]),
      .rast_pt(triangle_2d[0]),
      .rast_pt_valid(v1_valid)
  );

  vertex_3d_to_2d v2 ( // 63
      .clk(clk),
      .rst(rst),
      .camera(camera),
      .input_valid(input_valid),
      .vertex_3d(triangle_3d[1]),
      .rast_pt(triangle_2d[1]),
      .rast_pt_valid(v2_valid)
  );

  vertex_3d_to_2d v3 ( // 63
      .clk(clk),
      .rst(rst),
      .camera(camera),
      .input_valid(input_valid),
      .vertex_3d(triangle_3d[2]),
      .rast_pt(triangle_2d[2]),
      .rast_pt_valid(v3_valid)
  );

endmodule


module vertex_3d_to_2d ( // 63
    input wire clk,
    input wire rst,
    input wire view camera,
    input wire input_valid,
    input wire vec3_f16 vertex_3d,
    output vec3_i16 rast_pt,
    output wire rast_pt_valid
);

  logic screen_pt_valid, ndc_pt_valid;
  vec2_f16 screen_pt, ndc_pt;

//   ila my_ila (
//     .clk(clk),
//     .probe0(input_valid),
//     .probe1(screen_pt_valid),
//     .probe2(ndc_pt_valid),
//     .probe3(rast_pt_valid)
//   );

  vertex_project v_p ( // 21
      .clk(clk),
      .rst(rst),
      .cam_near_clip(camera.near_clip),
      .input_valid(input_valid),
      .vertex_3d(vertex_3d),
      .screen_pt(screen_pt),
      .screen_pt_valid(screen_pt_valid)
  );

  vertex_ndc_map v_ndc_m ( // 23
      .clk(clk),
      .rst(rst),
      .screen_pt(screen_pt),
      .canvas_dimensions(camera.canvas_dimensions),
      .input_valid(screen_pt_valid),
      .ndc_pt(ndc_pt),
      .ndc_pt_valid(ndc_pt_valid)
  );

  vertex_rasterize v_r ( // 19
      .clk(clk),
      .rst(rst),
      .input_valid(ndc_pt_valid),
      .ndc_pt(ndc_pt),
      .vertex_3d(vertex_3d),
      .image_dimensions(camera.image_dimensions),
      .rast_pt(rast_pt),
      .rast_pt_valid(rast_pt_valid)
  );

endmodule

`default_nettype wire
