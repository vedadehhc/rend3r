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

module pulse (
    input  wire  input_signal,
    input  wire  rst,
    input  wire  clk,
    output logic output_signal
);

  logic last_signal;
  always_ff @(posedge clk) begin
    if (rst) begin
      last_signal   <= 0;
      output_signal <= 0;
    end else begin

      last_signal <= input_signal;
      if (!last_signal && input_signal) begin
        output_signal <= 1;
      end else begin
        output_signal <= 0;
      end
    end
  end
endmodule
`default_nettype wire
