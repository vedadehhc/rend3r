`default_nettype none
module cdc_pipe #(
    DATA_WIDTH = 1
) (
    input wire rst,
    input wire src_clk,
    input wire dest_clk,
    input wire [DATA_WIDTH-1:0] input_signal_src_clk,
    output logic [DATA_WIDTH-1:0] output_signal_dest_clk
);

  logic [DATA_WIDTH-1:0] xfer_pipe;

  always_ff @(posedge dest_clk) begin
    if (rst) begin
      xfer_pipe <= 0;
      output_signal_dest_clk <= 0;
    end else begin
      {output_signal_dest_clk, xfer_pipe} <= {xfer_pipe, input_signal_src_clk};
    end
  end

endmodule
`default_nettype wire
