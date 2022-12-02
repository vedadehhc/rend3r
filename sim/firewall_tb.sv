`default_nettype none
`timescale 1ns / 1ps

module firewall_tb;

    logic clk;
    logic rst;
    logic axiiv;
    logic [1:0] axiid;
    logic axiov;
    logic [1:0] axiod;
    logic [47:0] addr;

    firewall fw(
        .clk(clk),
        .rst(rst),
        .axiiv(axiiv),
        .axiid(axiid),
        .axiov(axiov),
        .axiod(axiod)
    );

    // 50 MHz clock
    always begin
        #10;
        clk = !clk;
    end

    initial begin
        $dumpfile("firewall.vcd");
        $dumpvars(0, firewall_tb);
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

        // TC1: garbage MAC

        // dest
        for (integer i = 0; i < 24; i= i+1) begin
            axiiv = 1'b1;
            axiid = 2'b01;
            #20;
        end

        //src + length
        for (integer i = 0; i < 32; i= i+1) begin
            axiiv = 1'b1;
            axiid = 2'b00;
            #20;
        end

        // data + fcs
        for (integer i = 0; i < 100; i= i+1) begin
            axiiv = 1'b1;
            axiid = 2'b10;
            #20;
        end

        axiiv = 1'b0;
        #400;

        // TC2: global

        // dest
        for (integer i = 0; i < 24; i= i+1) begin
            axiiv = 1'b1;
            axiid = 2'b11;
            #20;
        end

        //src + length
        for (integer i = 0; i < 32; i= i+1) begin
            axiiv = 1'b1;
            axiid = 2'b00;
            #20;
        end

        // data + fcs
        for (integer i = 0; i < 100; i= i+1) begin
            axiiv = 1'b1;
            axiid = 2'b10;
            #20;
        end

        axiiv = 1'b0;
        #400;

        // TC3: specific

        // dest
        addr = 48'h69_69_5A_06_54_91;
        for (integer i = 0; i < 24; i= i+1) begin
            axiiv = 1'b1;
            axiid = addr[47:46];
            addr = {addr[45:0], addr[47:46]};
            #20;
        end

        //src + length
        for (integer i = 0; i < 32; i= i+1) begin
            axiiv = 1'b1;
            axiid = 2'b00;
            #20;
        end

        // data + fcs
        for (integer i = 0; i < 100; i= i+1) begin
            axiiv = 1'b1;
            axiid = 2'b10;
            #20;
        end

        axiiv = 1'b0;
        #400;

        $display("\nFinishing Sim");
        $finish;
    end
endmodule

`default_nettype wire
