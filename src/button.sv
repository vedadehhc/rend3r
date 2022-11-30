`default_nettype none
module button (
    input  wire  clk,
    input  wire  rst,
    input  wire  raw_in,
    output logic pulse_out,
    output logic clean_out
);

  logic clean_btn;
  assign clean_out = clean_btn;

  debouncer deb (
      .clk_in(clk),
      .rst_in(rst),
      .dirty_in(raw_in),
      .clean_out(clean_btn)
  );

  pulse pul (
      .clk(clk),
      .rst(rst),
      .input_signal(clean_btn),
      .output_signal(pulse_out)
  );

endmodule
`default_nettype wire
