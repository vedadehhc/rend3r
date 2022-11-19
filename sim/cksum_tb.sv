`default_nettype none
`timescale 1ns / 1ps

`define MESSAGE	168'h4261_7272_7921_2042_7265_616b_6661_7374_2074_696d65
`define CKSUM	32'h1a3a_ccb2


module cksum_tb;

    logic clk;
    logic rst;
    logic axiiv;
    logic [1:0] axiid;
    logic done;
    logic kill;
    logic [167:0] msg;
    logic [31:0] sum;

    cksum fcs(
        .clk(clk),
        .rst(rst),
        .axiiv(axiiv),
        .axiid(axiid),
        .done(done),
        .kill(kill)
    );

    // 50 MHz clock
    always begin
        #10;
        clk = !clk;
    end

    initial begin
        $dumpfile("cksum.vcd");
        $dumpvars(0, cksum_tb);
        $display("Starting Sim");

        clk = 1'b0;
        rst = 1'b0;
        axiiv = 1'b0;
        axiid = 32'b0;
        #20;
        #20;
        rst = 1'b1;
        #20;
        rst = 1'b0;
        #20;
        #20;

        // TC1: tiny 1 bit message
        axiiv = 1'b1;
        axiid = 2'b10;
        #20;
        axiiv = 1'b0;
        #80;

        // TC2: 168 bit message, 0 crc
        msg = 168'h4261_7272_7921_2042_7265_616b_6661_7374_2074_696d65;
        for (integer i = 0; i < 168; i = i+2) begin
            axiiv = 1'b1;
            axiid = msg[167:166];
            msg = {msg[165:0], msg[167:166]};
            #20;
        end

        // FCS
        for (integer i = 0; i < 16; i=i+1) begin
            axiiv = 1'b1;
            axiid = 2'b00;
            #20;
        end

        axiiv = 1'b0;
        #400;

        // TC3: 168 bit message, correct crc
        msg = 168'h4261_7272_7921_2042_7265_616b_6661_7374_2074_696d65;
        // msg = 168'h656d69_7420_7473_6166_6b61_6572_4220_2179_7272_6142;
        for (integer i = 0; i < 168; i = i+2) begin
            axiiv = 1'b1;
            axiid = msg[167:166];
            #20;
            msg = {msg[165:0], msg[167:166]};
        end

        // FCS
        sum = 32'h1a3a_ccb2;
        for (integer i = 0; i < 32; i = i+2) begin
            axiiv = 1'b1;
            axiid = sum[31:30];
            sum = {sum[29:0], sum[31:30]};
            #20;
        end

        axiiv = 1'b0;
        #400;

        $display("\nFinishing Sim");
        $finish;
    end
endmodule

`default_nettype wire
