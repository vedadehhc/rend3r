`default_nettype none
`timescale 1ns / 1ps

module ether_tb;

    logic clk;
    logic rst;
    logic [1:0] rxd;
    logic crsdv;
    logic axiov;
    logic [1:0] axiod;

    ether eth(
        .clk(clk),
        .rst(rst),
        .rxd(rxd),
        .crsdv(crsdv),
        .axiov(axiov),
        .axiod(axiod)
    );

    // 50 MHz clock
    always begin
        #10;
        clk = !clk;
    end

    initial begin
        $dumpfile("ether.vcd");
        $dumpvars(0, ether_tb);
        $display("Starting Sim");

        clk = 1'b0;
        rst = 1'b0;
        rxd = 2'b0;
        crsdv = 1'b0;
        #20;
        #20;
        rst = 1'b1;
        #20;
        rst = 1'b0;
        #20;

        
        //// TC1: valid preamble + 2 byte message
        crsdv = 1'b1;
        #80;

        // Valid preamble
        for (integer i = 0; i < 28; i = i+1) begin
            rxd = 2'b01;
            #20;
        end

        // Valid SFD
        rxd = 2'b01;
        #20;
        rxd = 2'b01;
        #20;
        rxd = 2'b01;
        #20;
        rxd = 2'b11;
        #20;

        // Dest
        for (integer i = 0; i < 24; i = i+1) begin
            rxd = 2'b11;
            #20;
        end

        // Src
        for (integer i = 0; i < 24; i = i+1) begin
            rxd = 2'b01;
            #20;
        end

        // Length/EtherType
        for (integer i = 0; i < 8; i = i+1) begin
            rxd = 2'b00;
            #20;
        end

        // Data (2 bytes)
        rxd = 2'b10;
        #20;
        rxd = 2'b00;
        #20;
        rxd = 2'b01;
        #20;
        rxd = 2'b00;
        #20;
        rxd = 2'b00;
        #20;
        rxd = 2'b01;
        #20;
        rxd = 2'b11;
        #20;
        rxd = 2'b00;
        #20;

        // FCS (4 bytes)
        rxd = 2'b11;
        #20;
        rxd = 2'b00;
        #20;
        rxd = 2'b01;
        #20;
        rxd = 2'b11;
        #20;

        rxd = 2'b11;
        #20;
        rxd = 2'b11;
        #20;
        rxd = 2'b10;
        #20;
        rxd = 2'b00;
        #20;
        
        rxd = 2'b00;
        #20;
        rxd = 2'b11;
        #20;
        rxd = 2'b01;
        #20;
        rxd = 2'b10;
        #20;
        
        rxd = 2'b00;
        #20;
        rxd = 2'b01;
        #20;
        rxd = 2'b10;
        #20;
        rxd = 2'b01;
        #20;

        // end
        rxd = 2'b00;
        crsdv = 1'b0;

        #20;
        #20;
        #20;

        //// TC2: false carrier in preamble
        crsdv = 1'b0;
        #20;
        crsdv = 1'b1;
        #80;

        // Invalid preamble
        for (integer i = 0; i < 28; i = i+1) begin
            if (i == 23) begin
                rxd = 2'b00;
            end else begin
                rxd = 2'b01;
            end
            #20;
        end

        // Valid SFD
        rxd = 2'b01;
        #20;
        rxd = 2'b01;
        #20;
        rxd = 2'b01;
        #20;
        rxd = 2'b11;
        #20;

        // Dest
        for (integer i = 0; i < 24; i = i+1) begin
            rxd = 2'b10;
            #20;
        end

        // Src
        for (integer i = 0; i < 24; i = i+1) begin
            rxd = 2'b01;
            #20;
        end

        // Length/EtherType
        for (integer i = 0; i < 8; i = i+1) begin
            rxd = 2'b00;
            #20;
        end

        // Data (2 bytes)
        rxd = 2'b10;
        #20;
        rxd = 2'b00;
        #20;
        rxd = 2'b01;
        #20;
        rxd = 2'b00;
        #20;
        rxd = 2'b00;
        #20;
        rxd = 2'b01;
        #20;
        rxd = 2'b11;
        #20;
        rxd = 2'b00;
        #20;

        // FCS (4 bytes)
        rxd = 2'b11;
        #20;
        rxd = 2'b00;
        #20;
        rxd = 2'b01;
        #20;
        rxd = 2'b11;
        #20;

        rxd = 2'b11;
        #20;
        rxd = 2'b11;
        #20;
        rxd = 2'b10;
        #20;
        rxd = 2'b00;
        #20;
        
        rxd = 2'b00;
        #20;
        rxd = 2'b11;
        #20;
        rxd = 2'b01;
        #20;
        rxd = 2'b10;
        #20;
        
        rxd = 2'b00;
        #20;
        rxd = 2'b01;
        #20;
        rxd = 2'b10;
        #20;
        rxd = 2'b01;
        #20;

        // end
        rxd = 2'b00;
        crsdv = 1'b0;

        #20;
        #20;
        #20;

        //// TC3: false carrier in SFD
        crsdv = 1'b0;
        #20;
        crsdv = 1'b1;
        #80;

        // Valid preamble
        for (integer i = 0; i < 28; i = i+1) begin
            rxd = 2'b01;
            #20;
        end

        // Invalid SFD
        rxd = 2'b01;
        #20;
        rxd = 2'b01;
        #20;
        rxd = 2'b01;
        #20;
        rxd = 2'b01;
        #20;

        // Dest
        for (integer i = 0; i < 24; i = i+1) begin
            rxd = 2'b10;
            #20;
        end

        // Src
        for (integer i = 0; i < 24; i = i+1) begin
            rxd = 2'b01;
            #20;
        end

        // Length/EtherType
        for (integer i = 0; i < 8; i = i+1) begin
            rxd = 2'b00;
            #20;
        end

        // Data (2 bytes)
        rxd = 2'b10;
        #20;
        rxd = 2'b00;
        #20;
        rxd = 2'b01;
        #20;
        rxd = 2'b00;
        #20;
        rxd = 2'b00;
        #20;
        rxd = 2'b01;
        #20;
        rxd = 2'b11;
        #20;
        rxd = 2'b00;
        #20;

        // FCS (4 bytes)
        rxd = 2'b11;
        #20;
        rxd = 2'b00;
        #20;
        rxd = 2'b01;
        #20;
        rxd = 2'b11;
        #20;

        rxd = 2'b11;
        #20;
        rxd = 2'b11;
        #20;
        rxd = 2'b10;
        #20;
        rxd = 2'b00;
        #20;
        
        rxd = 2'b00;
        #20;
        rxd = 2'b11;
        #20;
        rxd = 2'b01;
        #20;
        rxd = 2'b10;
        #20;
        
        rxd = 2'b00;
        #20;
        rxd = 2'b01;
        #20;
        rxd = 2'b10;
        #20;
        rxd = 2'b01;
        #20;

        // end
        rxd = 2'b00;
        crsdv = 1'b0;

        #20;
        #20;
        #20;

        //// TC4: Valid message - 100 bytes
        crsdv = 1'b0;
        #20;
        crsdv = 1'b1;
        #80;

        // Valid preamble
        for (integer i = 0; i < 28; i = i+1) begin
            rxd = 2'b01;
            #20;
        end

        // Valid SFD
        rxd = 2'b01;
        #20;
        rxd = 2'b01;
        #20;
        rxd = 2'b01;
        #20;
        rxd = 2'b11;
        #20;

        // Dest
        for (integer i = 0; i < 24; i = i+1) begin
            rxd = 2'b11;
            #20;
        end

        // Src
        for (integer i = 0; i < 24; i = i+1) begin
            rxd = 2'b01;
            #20;
        end

        // Length/EtherType
        for (integer i = 0; i < 8; i = i+1) begin
            rxd = 2'b00;
            #20;
        end

        // Data (100 bytes)

        for (integer i = 0; i < 100; i= i+1) begin
            rxd = 2'b00;
            #20;
            rxd = 2'b01;
            #20;
            rxd = 2'b10;
            #20;
            rxd = 2'b11;
            #20;
        end 

        // FCS (4 bytes)
        rxd = 2'b11;
        #20;
        rxd = 2'b00;
        #20;
        rxd = 2'b01;
        #20;
        rxd = 2'b11;
        #20;

        rxd = 2'b11;
        #20;
        rxd = 2'b11;
        #20;
        rxd = 2'b10;
        #20;
        rxd = 2'b00;
        #20;
        
        rxd = 2'b00;
        #20;
        rxd = 2'b11;
        #20;
        rxd = 2'b01;
        #20;
        rxd = 2'b10;
        #20;
        
        rxd = 2'b00;
        #20;
        rxd = 2'b01;
        #20;
        rxd = 2'b10;
        #20;
        rxd = 2'b01;
        #20;

        // end
        rxd = 2'b00;
        crsdv = 1'b0;

        #20;
        #20;
        #20;

        $display("\nFinishing Sim");
        $finish;
    end
endmodule

`default_nettype wire
