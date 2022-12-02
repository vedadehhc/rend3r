`timescale 1ns / 1ps
//
`default_nettype none

module pix_write_tb;

  //make logics for inputs and outputs!
  logic rst;
  logic clk;

  pix_write p (
      .sys_clk(clk),
      .sys_rst(rst)
  );

  always begin
    #2.5;  //2.5 switch: period 5 ns -> 200Hz
    clk = !clk;
  end

  //initial block...this is our test simulation
  initial begin
    $dumpfile("pix_write.vcd");  //file to store value change dump (vcd)
    $dumpvars(0, pix_write_tb);  //store everything at the current level and below
    $display("Starting Sim");  //print nice message
    clk = 0;
    rst = 0;
    // output_signal_dest_clk = 1;
    #22.5  //wait
    rst = 1;
    #20;  //hold
    rst = 0;
    #20;

    #600000;
    $finish;

  end
endmodule  //counter_tb

`default_nettype wire
