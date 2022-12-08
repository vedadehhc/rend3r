`default_nettype none
module pipe #(
    LENGTH = 1,
    WIDTH = 1
) (
    input  wire  clk,
    input  wire  rst,
    input  wire  [WIDTH-1:0] in,
    output logic [WIDTH-1:0] out,
    output logic [LENGTH-1:0][WIDTH-1:0]  line
);

  logic temp;
  assign out  = line[LENGTH-1];
  assign temp = line << 1;

  always_ff @(posedge clk) begin
    if (rst) begin
      line <= 0;
    end else begin
    line[0] <= in;
    for (int i = 0; i < LENGTH - 1; i++ ) begin
        line[i + 1] <= line[i];
    end

    end
  end
endmodule
`default_nettype wire
