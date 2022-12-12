`default_nettype none
import types::*;

module triangle_3d_to_2d (
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

  vertex_3d_to_2d v1 (
      .clk(clk),
      .rst(rst),
      .camera(camera),
      .input_valid(input_valid),
      .vertex_3d(triangle_3d[0]),
      .rast_pt(triangle_2d[0]),
      .rast_pt_valid(v1_valid)
  );

  vertex_3d_to_2d v2 (
      .clk(clk),
      .rst(rst),
      .camera(camera),
      .input_valid(input_valid),
      .vertex_3d(triangle_3d[1]),
      .rast_pt(triangle_2d[1]),
      .rast_pt_valid(v2_valid)
  );

  vertex_3d_to_2d v3 (
      .clk(clk),
      .rst(rst),
      .camera(camera),
      .input_valid(input_valid),
      .vertex_3d(triangle_3d[2]),
      .rast_pt(triangle_2d[2]),
      .rast_pt_valid(v3_valid)
  );

endmodule


module vertex_3d_to_2d (
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

  vertex_project v_p (
      .clk(clk),
      .rst(rst),
      .cam_near_clip(camera.near_clip),
      .input_valid(input_valid),
      .vertex_3d(vertex_3d),
      .screen_pt(screen_pt),
      .screen_pt_valid(screen_pt_valid)
  );

  vertex_ndc_map v_ndc_m (
      .clk(clk),
      .rst(rst),
      .screen_pt(screen_pt),
      .canvas_dimensions(camera.canvas_dimensions),
      .input_valid(screen_pt_valid),
      .ndc_pt(ndc_pt),
      .ndc_pt_valid(ndc_pt_valid)
  );

  vertex_rasterize v_r (
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
