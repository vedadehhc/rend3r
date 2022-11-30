`default_nettype none
module pipe #(
    LENGTH = 1
) (
    input  wire  clk,
    input  wire  rst,
    input  wire  in,
    output logic out
);

  logic [LENGTH-1:0] line;

  logic temp;
  assign out  = line[LENGTH-1];
  assign temp = line << 1;

  always_ff @(posedge clk) begin
    if (rst) begin
      line <= 0;
    end else begin
      line <= {temp[LENGTH-1:1], in};
    end
  end
endmodule
`default_nettype wire
