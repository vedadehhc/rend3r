`default_nettype none
`timescale 1ns / 1ps

module bitorder_tb;

    logic clk;
    logic rst;
    logic axiiv;
    logic [1:0] axiid;
    logic axiov;
    logic [1:0] axiod;
    // logic [47:0] addr;

    bitorder bo(
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
        $dumpfile("bitorder.vcd");
        $dumpvars(0, bitorder_tb);
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

        // TC1: 4 bits sent
        axiiv = 1'b1;
        axiid = 2'b00;
        #20;
        axiiv = 1'b1;
        axiid = 2'b01;
        #20;

        axiiv = 1'b0;
        #400;

        // TC2: 1 byte sent
        axiiv = 1'b1;
        axiid = 2'b00;
        #20;
        axiiv = 1'b1;
        axiid = 2'b01;
        #20;
        axiiv = 1'b1;
        axiid = 2'b00;
        #20;
        axiiv = 1'b1;
        axiid = 2'b01;
        #20;

        axiiv = 1'b0;
        #400;

        // TC3: 2 byte sent
        axiiv = 1'b1;
        axiid = 2'b00;
        #20;
        axiiv = 1'b1;
        axiid = 2'b01;
        #20;
        axiiv = 1'b1;
        axiid = 2'b00;
        #20;
        axiiv = 1'b1;
        axiid = 2'b01;
        #20;

        axiiv = 1'b1;
        axiid = 2'b11;
        #20;
        axiiv = 1'b1;
        axiid = 2'b01;
        #20;        
        axiiv = 1'b1;
        axiid = 2'b11;
        #20;
        axiiv = 1'b1;
        axiid = 2'b01;
        #20;

        axiiv = 1'b0;
        #400;

        // TC4: 2 byte + 2 bits sent
        axiiv = 1'b1;
        axiid = 2'b00;
        #20;
        axiiv = 1'b1;
        axiid = 2'b01;
        #20;
        axiiv = 1'b1;
        axiid = 2'b00;
        #20;
        axiiv = 1'b1;
        axiid = 2'b01;
        #20;

        axiiv = 1'b1;
        axiid = 2'b11;
        #20;
        axiiv = 1'b1;
        axiid = 2'b01;
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

        axiiv = 1'b0;
        #400;


        // TC4: 100 byte + 2 bits sent
        for (integer i = 0; i < 100; i=i+1) begin
            axiiv = 1'b1;
            axiid = 2'b00;
            #20;
            axiiv = 1'b1;
            axiid = 2'b01;
            #20;
            axiiv = 1'b1;
            axiid = 2'b11;
            #20;
            axiiv = 1'b1;
            axiid = 2'b01;
            #20;
        end

        axiiv = 1'b1;
        axiid = 2'b01;
        #20;

        axiiv = 1'b0;
        #400;

        $display("\nFinishing Sim");
        $finish;
    end
endmodule

`default_nettype wire
