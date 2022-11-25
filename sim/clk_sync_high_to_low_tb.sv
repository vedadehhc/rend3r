`timescale 1ns / 1ps
//
`default_nettype none

module clk_sync_high_low_tb;

  //make logics for inputs and outputs!
  logic rst;
  logic src_clk;
  logic dest_clk;
  logic input_signal_src_clk;
  logic output_signal_dest_clk;

  clk_sync_high_to_low clk_sync (
      .rst(rst),
      .src_clk(src_clk),
      .dest_clk(dest_clk),
      .input_signal_src_clk(input_signal_src_clk),
      .output_signal_dest_clk(output_signal_dest_clk)
  );

  always begin
    #6;  //6ns switch: period of 12ns -> ~81.25 MHz
    dest_clk = !dest_clk;
  end

  always begin
    #2.5;  //2.5 switch: period 5 ns -> 200Hz
    src_clk = !src_clk;
  end

  //initial block...this is our test simulation
  initial begin
    $dumpfile("cshl.vcd");  //file to store value change dump (vcd)
    $dumpvars(0, clk_sync_high_low_tb);  //store everything at the current level and below
    $display("Starting Sim");  //print nice message
    src_clk = 0;
    dest_clk = 0;
    rst = 0;
    input_signal_src_clk = 0;
    // output_signal_dest_clk = 1;
    #22.5 //wait
    rst = 1;
    #20;  //hold
    rst = 0;
    #20;

    #40;
    input_signal_src_clk = 1;
    #5 
    input_signal_src_clk = 0;
    #5

    // input_signal_src_clk = 1;
    // #5 
    // input_signal_src_clk = 0;

    #600 $finish;

  end
endmodule  //counter_tb

`default_nettype wire
