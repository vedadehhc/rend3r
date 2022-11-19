`default_nettype none
`timescale 1ns / 1ps

module integration_tb;

    logic clk;
    logic clk_50mhz;
    assign clk_50mhz  = clk;
    logic rst;
    logic axiiv;
    logic [1:0] axiid;

    logic ether_axiov;
    logic [1:0] ether_axiod;

    ether ethernet(
        .clk(clk_50mhz),
        .rst(rst),
        .rxd(axiid),
        .crsdv(axiiv),
        .axiov(ether_axiov),
        .axiod(ether_axiod)
    );

    logic bo_axiov;
    logic [1:0] bo_axiod;

    bitorder bo (
        .clk(clk_50mhz),
        .rst(rst),
        .axiiv(ether_axiov),
        .axiid(ether_axiod),
        .axiov(bo_axiov),
        .axiod(bo_axiod)
    );

    logic fw_axiov;
    logic [1:0] fw_axiod;

    firewall fw (
        .clk(clk_50mhz),
        .rst(rst),
        .axiiv(bo_axiov),
        .axiid(bo_axiod),
        .axiov(fw_axiov),
        .axiod(fw_axiod)
    );

    logic agg_axiov;
    logic [31:0] agg_axiod;

    aggregate agg (
        .clk(clk_50mhz),
        .rst(rst),
        .axiiv(fw_axiov),
        .axiid(fw_axiod),
        .axiov(agg_axiov),
        .axiod(agg_axiod)
    );


    // 50 MHz clock
    always begin
        #10;
        clk = !clk;
    end

    initial begin
        $dumpfile("integration.vcd");
        $dumpvars(0, integration_tb);
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


        // TC3: 32 bit message (with FCS)
        // Valid preamble
        for (integer i = 0; i < 28; i = i+1) begin
            axiiv = 1'b1;
            axiid = 2'b01;
            #20;
        end

        // Valid SFD
        axiid = 2'b01;
        #20;
        axiid = 2'b01;
        #20;
        axiid = 2'b01;
        #20;
        axiid = 2'b11;
        #20;

        // Dest
        for (integer i = 0; i < 24; i = i+1) begin
            axiid = 2'b11;
            #20;
        end

        // Src
        for (integer i = 0; i < 24; i = i+1) begin
            axiid = 2'b01;
            #20;
        end

        // Length/EtherType
        for (integer i = 0; i < 8; i = i+1) begin
            axiid = 2'b00;
            #20;
        end

        // data
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
        
        // fcs
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
