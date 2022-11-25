`default_nettype none
module fifo_27 (
    input wire rst,
    input wire read_clk,
    input wire write_clk,
    input wire [26:0] data_in,
    input wire write_valid,
    input wire read_valid,
    output logic [26:0] data_out,
    output logic full,
    output logic empty,
);

logic almost_full, almost_empty, write_rst_busy, read_rst_busy;

fifo_generator_1 inner_fifo (
  .rst(rst),
  .wr_clk(write_clk),
  .rd_clk(read_clk),
  .din(data_in),
  .wr_en(write_valid),
  .rd_en(read_valid),
  .dout(data_out),
  .full(full),
  .empty(empty),
  .wr_rst_busy(write_rst_busy),
  .rd_rst_busy(read_rst_busy)
);

endmodule
`default_nettype wire