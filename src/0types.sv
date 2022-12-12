package types;
  typedef logic [15:0] f16;  // 16 bit float point
  typedef logic [15:0] fx13;  // 13 bit fixed point
  typedef logic signed [15:0] i16;  // 13 bit integer
  typedef f16 vec3_f16[3];
  typedef f16 vec2_f16[2];
  typedef i16 vec3_i16[3];

  typedef vec3_f16 tri_3d[3];
  typedef vec3_i16 tri_2d[3]; // is a vec3 but the third element is zdist
  

 typedef struct {
    f16 near_clip;
    vec3_f16 position;
    vec2_f16 canvas_dimensions;
    vec2_f16 image_dimensions;
 } view;

endpackage
