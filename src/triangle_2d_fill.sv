`default_nettype none
import types::*;

module triangle_2d_fill (
    input wire clk,
    input wire rst,
    input wire [11:0] hcount,
    input wire [11:0] vcount,
    input wire tri_2d triangle,
    output logic is_within
);

  vec3_i16 point;
  logic signed [25:0] d0, d1, d2;

  assign point[0] = hcount;
  assign point[1] = vcount;
  assign point[2] = 'b0;
  // assign point = {vcount, hcount};

  logic has_neg, has_pos;

  planar_sign pd0 (
      .clk(clk),
      .rst(rst),
      .point(point),
      .vertex_a(triangle[0]),
      .vertex_b(triangle[1]),
      .sign(d0)
  );
  planar_sign pd1 (
      .clk(clk),
      .rst(rst),
      .point(point),
      .vertex_a(triangle[1]),
      .vertex_b(triangle[2]),
      .sign(d1)
  );
  planar_sign pd2 (
      .clk(clk),
      .rst(rst),
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
    input wire clk,
    input wire rst,
    input wire vec3_i16 point,
    input wire vec3_i16 vertex_a,
    input wire vec3_i16 vertex_b,
    output logic signed [33:0] sign
);

  logic signed [12:0] a_x, a_y, b_x, b_y, p_x, p_y;

  assign a_x = $signed({1'b0, vertex_a[0][11:0]});
  assign a_y = $signed({1'b0, vertex_a[1][11:0]});
  assign b_x = $signed({1'b0, vertex_b[0][11:0]});
  assign b_y = $signed({1'b0, vertex_b[1][11:0]});
  assign p_x = $signed({1'b0, point[0][11:0]});
  assign p_y = $signed({1'b0, point[1][11:0]});

  logic signed [25:0] ip1, ip2, ip1_a, ip1_b, ip2_a, ip2_b;


  always_ff @(posedge clk) begin
    if (rst) begin
      ip1   <= 0;
      ip2   <= 0;

      ip1_a <= 0;
      ip1_b <= 0;

      ip2_a <= 0;
      ip2_b <= 0;

      sign  <= 0;
    end else begin
      ip1_a <= (p_x - b_x);
      ip1_b <= (a_y - b_y);

      ip2_a <= (a_x - b_x);
      ip2_b <= (p_y - b_y);

      ip1   <= ip1_a * ip1_b;
      ip2   <= ip2_a * ip2_b;

      sign  <= ip1 - ip2;
    end
  end

  //   assign ip1_a = 

  //   assign ip1 = (p_x - b_x) * (a_y - b_y);
  //   assign ip2 = (a_x - b_x) * (p_y - b_y);

  //   assign sign = ip1 - ip2;
endmodule
`default_nettype wire