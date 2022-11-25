`default_nettype none
//
`timescale 1ns / 1ps
// only syncs high pulses from fast clock to slow clock
module clk_sync_high_to_low (
    input  wire  rst,
    input  wire  src_clk,
    input  wire  dest_clk,
    input  wire  input_signal_src_clk,
    output logic output_signal_dest_clk

);

  logic [3:0] src_was_high;
  logic dest_clk_was_high;

//   assign output_signal_dest_clk = input_signal_src_clk | src_was_high;

  always_ff @(posedge src_clk) begin
    if (rst) begin
      dest_clk_was_high <= 0;
      src_was_high <= 0;
    end else begin
      if (input_signal_src_clk) begin
        src_was_high <= src_was_high + 1;
      end else if (output_signal_dest_clk && src_was_high) begin
        if (dest_clk) begin
          dest_clk_was_high <= 1;
        end
        if (!dest_clk && dest_clk_was_high) begin
          dest_clk_was_high <= 0;
          src_was_high <= src_was_high - 1;
        end
      end

    end
  end

  always_ff @(posedge dest_clk) begin
    if (rst) begin
      output_signal_dest_clk <= 0;
    end else begin
      if (src_was_high) begin
          output_signal_dest_clk <= 1;
      end else begin
          output_signal_dest_clk <= 0;
      end
    end
  end


endmodule
