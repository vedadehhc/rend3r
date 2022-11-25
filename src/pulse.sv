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
