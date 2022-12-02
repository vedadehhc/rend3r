`timescale 1ns / 1ps
//
`default_nettype none

module pipe_tb;

  //make logics for inputs and outputs!
  logic rst;
  logic clk;
  logic pipe_in;
  logic pipe_out;

  pipe #(.LENGTH(10)) p (
      .rst(rst),
      .clk(clk),
      .in (pipe_in),
      .out(pipe_out)
  );

  //   always begin
  //     #6;  //6ns switch: period of 12ns -> ~81.25 MHz
  //     clk = !clk;
  //   end

  always begin
    #2.5;  //2.5 switch: period 5 ns -> 200Hz
    clk = !clk;
  end

  //initial block...this is our test simulation
  initial begin
    $dumpfile("pipe.vcd");  //file to store value change dump (vcd)
    $dumpvars(0, pipe_tb);  //store everything at the current level and below
    $display("Starting Sim");  //print nice message
    clk = 0;
    rst = 0;
    pipe_in = 0;
    // output_signal_dest_clk = 1;
    #22.5  //wait
      rst = 1;
    #20;  //hold
    rst = 0;
    #20;

    #100; 
    pipe_in = 1;
    #12;
    pipe_in = 0;
    #240
    pipe_in = 1;
    #36;
    pipe_in = 0;

    #600;
    $finish;

  end
endmodule  //counter_tb

`default_nettype wire
