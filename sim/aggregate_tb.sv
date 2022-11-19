`default_nettype none
`timescale 1ns / 1ps

module aggregate_tb;

    logic clk;
    logic rst;
    logic axiiv;
    logic [1:0] axiid;
    logic axiov;
    logic [31:0] axiod;

    aggregate agg(
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
        $dumpfile("aggregate.vcd");
        $dumpvars(0, aggregate_tb);
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

        // TC2: 32 bit message (no FCS)
        axiiv = 1'b1;
        axiid = 2'b01;
        #20;
        axiiv = 1'b1;
        axiid = 2'b00;
        #20;
        axiiv = 1'b1;
        axiid = 2'b00;
        #20;
        axiiv = 1'b1;
        axiid = 2'b11;
        #20;

        axiiv = 1'b1;
        axiid = 2'b01;
        #20;
        axiiv = 1'b1;
        axiid = 2'b01;
        #20;
        axiiv = 1'b1;
        axiid = 2'b00;
        #20;
        axiiv = 1'b1;
        axiid = 2'b11;
        #20;

        axiiv = 1'b1;
        axiid = 2'b11;
        #20;
        axiiv = 1'b1;
        axiid = 2'b11;
        #20;
        axiiv = 1'b1;
        axiid = 2'b10;
        #20;
        axiiv = 1'b1;
        axiid = 2'b01;
        #20;

        axiiv = 1'b1;
        axiid = 2'b00;
        #20;
        axiiv = 1'b1;
        axiid = 2'b10;
        #20;
        axiiv = 1'b1;
        axiid = 2'b11;
        #20;
        axiiv = 1'b1;
        axiid = 2'b00;
        #20;

        axiiv = 1'b0;
        #400;


        // TC3: 32 bit message (with FCS)
        axiiv = 1'b1;
        axiid = 2'b01;
        #20;
        axiiv = 1'b1;
        axiid = 2'b00;
        #20;
        axiiv = 1'b1;
        axiid = 2'b00;
        #20;
        axiiv = 1'b1;
        axiid = 2'b11;
        #20;

        axiiv = 1'b1;
        axiid = 2'b01;
        #20;
        axiiv = 1'b1;
        axiid = 2'b01;
        #20;
        axiiv = 1'b1;
        axiid = 2'b00;
        #20;
        axiiv = 1'b1;
        axiid = 2'b11;
        #20;

        axiiv = 1'b1;
        axiid = 2'b11;
        #20;
        axiiv = 1'b1;
        axiid = 2'b11;
        #20;
        axiiv = 1'b1;
        axiid = 2'b10;
        #20;
        axiiv = 1'b1;
        axiid = 2'b01;
        #20;

        axiiv = 1'b1;
        axiid = 2'b00;
        #20;
        axiiv = 1'b1;
        axiid = 2'b10;
        #20;
        axiiv = 1'b1;
        axiid = 2'b11;
        #20;
        axiiv = 1'b1;
        axiid = 2'b00;
        #20;

        for (integer i = 0; i < 16; i=i+1) begin
            axiiv = 1'b1;
            axiid = 2'b00;
            #20;
        end

        axiiv = 1'b0;
        #400;


        // TC4: 96 bit message (with FCS)

        // first 32
        for (integer i = 0; i < 16; i =i +1) begin
            axiiv = 1'b1;
            axiid = 2'b10;
            #20;
        end

        // second 32
        for (integer i = 0; i < 16; i =i +1) begin
            axiiv = 1'b1;
            axiid = 2'b11;
            #20;
        end

        // third 32
        for (integer i = 0; i < 16; i =i +1) begin
            axiiv = 1'b1;
            axiid = 2'b01;
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

        $display("\nFinishing Sim");
        $finish;
    end
endmodule

`default_nettype wire
