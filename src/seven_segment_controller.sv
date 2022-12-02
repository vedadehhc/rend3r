`default_nettype none

module seven_segment_controller #(parameter COUNT_TO = 'd100_000)
                        (input wire         clk_in,
                         input wire         rst_in,
                         input wire [31:0]  val_in,
                         output logic[6:0]   cat_out,
                         output logic[7:0]   an_out
                        );
  logic [7:0]	segment_state;
  logic [31:0]	segment_counter;
  logic [3:0]	routed_vals;
  logic [6:0]	led_out;
  
  bto7s mbto7s (.x_in(routed_vals), .s_out(led_out));
  assign cat_out = ~led_out; //<--note this inversion is needed
  assign an_out = ~segment_state; //note this inversion is needed

  always_comb begin
    routed_vals = 4'b0000;
    for (integer i = 0; i < 8; i = i + 1) begin
        if (segment_state[i]) begin
            routed_vals[3] = val_in[4*i+3];
            routed_vals[2] = val_in[4*i+2];
            routed_vals[1] = val_in[4*i+1];
            routed_vals[0] = val_in[4*i];
        end
    end
  end

  always_ff @(posedge clk_in)begin
    if (rst_in)begin
      segment_state <= 8'b0000_0001;
      segment_counter <= 32'b0;
    end else begin
      if (segment_counter == COUNT_TO) begin
        segment_counter <= 32'd0;
        segment_state <= {segment_state[6:0],segment_state[7]};
    	end else begin
    	  segment_counter <= segment_counter +1;
    	end
    end
  end
endmodule // seven_segment_controller

module bto7s(
        input wire [3:0]   x_in,
        output logic [6:0] s_out
        );
       // array of bits that are "one hot" with numbers 0 through 15
        logic [15:0] num;
        assign num[0] = ~x_in[3] && ~x_in[2] && ~x_in[1] && ~x_in[0];
        assign num[1] = ~x_in[3] && ~x_in[2] && ~x_in[1] && x_in[0];
        assign num[2] = x_in == 4'd2;
        assign num[3] = x_in == 4'd3;
        assign num[4] = x_in == 4'd4;
        assign num[5] = x_in == 4'd5;
        assign num[6] = x_in == 4'd6;
        assign num[7] = x_in == 4'd7;
        assign num[8] = x_in == 4'd8;
        assign num[9] = x_in == 4'd9;
        assign num[10] = x_in == 4'd10;
        assign num[11] = x_in == 4'd11;
        assign num[12] = x_in == 4'd12;
        assign num[13] = x_in == 4'd13;
        assign num[14] = x_in == 4'd14;
        assign num[15] = x_in == 4'd15;

        /* assign the seven output segments, sa through sg, using a "sum of products"
         * approach and the diagram above.
         */
        assign s_out[0] = ~(num[1] || num[4] || num[4'hb] || num[4'hd]);
        assign s_out[1] = ~(num[5] || num[6] || num[4'hb] || num[4'hc] || num[4'he] || num[4'hf]);
        assign s_out[2] = ~(num[2] || num[4'hc] || num[4'he] || num[4'hf]);
        assign s_out[3] = ~(num[1] || num[4] || num[7] || num[4'ha] || num[4'hf]);
        assign s_out[4] = (num[0] || num[2] || num[6] || num[8] || num[4'ha] || num[4'hb] || num[4'hc] || num[4'hd] || num[4'he] || num[4'hf]);
        assign s_out[5] = ~(num[1] || num[2] || num[3] || num[7] || num[4'hd]);
        assign s_out[6] = ~(num[0] || num[1] || num[7] || num[4'hc]); 
endmodule


`default_nettype wire