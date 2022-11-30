module triangle_fill (
    input wire clk,
    input wire [10:0] hcount,
    input wire [10:0] vcount,
    input wire [2:0][1:0][10:0] triangle,
    output logic is_within
);

  logic [1:0][10:0] point;
  logic signed [23:0] d0, d1, d2;

  assign point = {vcount, hcount};

  logic has_neg, has_pos;

  planar_sign pd0 (
      .point(point),
      .vertex_a(triangle[0]),
      .vertex_b(triangle[1]),
      .sign(d0)
  );
  planar_sign pd1 (
      .point(point),
      .vertex_a(triangle[1]),
      .vertex_b(triangle[2]),
      .sign(d1)
  );
  planar_sign pd2 (
      .point(point),
      .vertex_a(triangle[2]),
      .vertex_b(triangle[0]),
      .sign(d2)
  );

  assign has_neg   = (d0 < 0) | (d1 < 0) | (d2 < 0);
  assign has_pos   = (d0 > 0) | (d1 > 0) | (d2 > 0);

  assign is_within = ~(has_neg & has_pos);

endmodule

module planar_sign (
    input wire [1:0][10:0] point,
    input wire [1:0][10:0] vertex_a,
    input wire [1:0][10:0] vertex_b,
    output logic signed [23:0] sign
);

  logic signed [11:0] a_x, a_y, b_x, b_y, p_x, p_y;

  assign a_x  = $signed({1'b0, vertex_a[0]});
  assign a_y  = $signed({1'b0, vertex_a[1]});
  assign b_x  = $signed({1'b0, vertex_b[0]});
  assign b_y  = $signed({1'b0, vertex_b[1]});
  assign p_x  = $signed({1'b0, point[0]});
  assign p_y  = $signed({1'b0, point[1]});

  logic signed [23:0] ip1, ip2;

  assign ip1 = (p_x - b_x) * (a_y - b_y);
  assign ip2 = (a_x - b_x) * (p_y - b_y);

  assign sign = ip1 - ip2;
endmodule
