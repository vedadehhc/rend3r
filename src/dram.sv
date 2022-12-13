`timescale 1ns / 1ps

/* 4:1 data rate + DDR => 16 * 8 = 128 */
// `define BURST_BITS 128
// `define CACHE_BLOCK_BYTES 64

// `define CACHE_BLOCK_BITS (`CACHE_BLOCK_BYTES * 8)
// `define CACHE_BLOCK_BURSTS (`CACHE_BLOCK_BITS / BURST_BITS)
// `define BURST_CTR_BITS $clog2(CACHE_BLOCK_BURSTS)

/* Hard coded */
// `define DRAM_ADDR_BITS 27

/* Xilinx, why? */
`define READ_CMD 3'b001
`define WRITE_CMD 3'b000

/* State machines (!! so much _stuff_!) */
`define DISPATCH_IDLE 2'b00
`define DISPATCH_WRITE_SEND 2'b01
`define DISPATCH_READ_SEND 2'b10
`define DISPATCH_READ_WAIT 2'b11

`define Idle 0


/* The DRAM module generates an 81.25 MHz clock
 * which we control it with (4:1 ratio). The controller
 * takes in a 200 MHz clock from the rest of the processor,
 * but this 200 MHz clock is not used throughout the system bus..
 *
 * This module allows for synchronous `CACHE_BLOCK_BITS reads and writes.
 * Writes are non-blocking, and it can be assumed that reads will not
 * be reordered from writes (i.e. sequential consistency of the memory).
 * Reads are blocking and generally slower.
 */


module dram #(
    parameter DRAM_ADDR_BITS = 27,
    parameter CACHE_BLOCK_BYTES = 64,
    parameter BURST_BITS = 128
) (
    pclk,
    rst,
    sclk,
    read_ready,
    read_request,
    read_address,
    read_response,
    read_data,
    write_ready,
    write_request,
    write_address,
    write_data,

    init_calib_complete,
    // dispatch_state,
    // read_resp_ctr,
    // app_rd_data_valid,

    /* DDR output signals strung straight to the top level */
    ddr2_addr,
    ddr2_ba,
    ddr2_ras_n,
    ddr2_cas_n,
    ddr2_we_n,
    ddr2_ck_p,
    ddr2_ck_n,
    ddr2_cke,
    ddr2_cs_n,
    ddr2_dm,
    ddr2_odt,
    ddr2_dq,
    ddr2_dqs_p,
    ddr2_dqs_n
);

  localparam CACHE_BLOCK_BITS = CACHE_BLOCK_BYTES * 8;
  localparam CACHE_BLOCK_BURSTS = CACHE_BLOCK_BITS / BURST_BITS;
  localparam BURST_CTR_BITS = $clog2(CACHE_BLOCK_BURSTS);

  /* double-a batteries
	 * we have the incoming processor clock, and then
	 * the DRAM controller generates an 81.25 MHz clock
	 * at which the rest of the system interface runs
	 */
  input logic pclk, rst;
  output logic sclk;

  /* This module wraps around the i/o of entire cache lines
	 * at once...so we have really really wide inputs
	 */

  /* Reads from the DRAM
	 * Note that we have a 16 bit bus, so we
	 * absolutely _need_ to be half-word aligned
	 * on our accesses. Our cache kind of enforces this
	 * which is nice... 
	 */
  input logic read_request;
  input logic [DRAM_ADDR_BITS-1:0] read_address;

  output logic read_ready, read_response;
  output logic [CACHE_BLOCK_BURSTS-1:0][BURST_BITS-1:0] read_data;

  /* Writes from the DRAM */
  input logic write_request;
  input logic [DRAM_ADDR_BITS-1:0] write_address;
  input logic [CACHE_BLOCK_BURSTS-1:0][BURST_BITS-1:0] write_data;

  output logic write_ready;

  // ifc_ila ila(.clk(sclk),
  // 	    .probe0(read_request),
  // 	    .probe1(read_address),
  // 	    .probe2(read_ready),
  // 	    .probe3(read_response),
  // 	    .probe4(read_data),
  // 	    .probe5(write_request),
  // 	    .probe6(write_address),
  // 	    .probe7(write_data),

  // 	    .probe8(dispatch_state),
  // 	    .probe9(read_req_ctr),
  // 	    .probe10(read_resp_ctr),
  // 	    .probe11(write_req_ctr),

  // 	    .probe12(app_addr),
  // 	    .probe13(app_cmd),
  // 	    .probe14(app_en),
  // 	    .probe15(app_wdf_data),
  // 	    .probe16(app_wdf_end),
  // 	    .probe17(app_wdf_wren),
  // 	    .probe18(app_rd_data),
  // 	    .probe19(app_rd_data_valid),
  // 	    .probe20(app_rdy),
  // 	    .probe21(app_wdf_rdy));

  /* Interfacing with the DRAM: routing to the top level... */
  output logic [12:0] ddr2_addr;
  output logic [2:0] ddr2_ba;

  output logic ddr2_ras_n, ddr2_cas_n;
  output logic ddr2_we_n;

  output logic ddr2_ck_p, ddr2_ck_n, ddr2_cke;
  output logic ddr2_cs_n;

  output logic [1:0] ddr2_dm;
  output logic ddr2_odt;

  output logic init_calib_complete;

  inout wire [15:0] ddr2_dq;
  inout wire [1:0] ddr2_dqs_n;
  inout wire [1:0] ddr2_dqs_p;

  /* Inputs to the controller we care about */
  logic [26:0] app_addr;
  logic [2:0] app_cmd;
  logic app_en;

  logic [127:0] app_wdf_data;
  logic app_wdf_end;
  logic [15:0] app_wdf_mask;
  logic app_wdf_wren;
  logic app_rd_data_end;

  /* And outputs we're interested in actually using */
  logic [127:0] app_rd_data;
  logic app_rd_data_valid;

  logic app_rdy;
  logic app_wdf_rdy;

  // ila_dram ila (
  //     .clk(sclk),
  //     .probe0(app_addr),
  //     .probe1(app_cmd),
  //     .probe2(app_en),

  //     .probe3(app_wdf_data),
  //     .probe4(app_wdf_end),
  //     .probe5(app_wdf_mask),
  //     .probe6(app_wdf_wren),

  //     .probe7(app_rd_data),
  //     .probe8(app_rd_data_valid),
  //     .probe9(app_rd_data_end),

  //     .probe10(app_rdy),
  //     .probe11(app_wdf_rdy),

  //     .probe12(read_req_ctr),  
  //     .probe13(read_resp_ctr), 
  //     .probe14(dispatch_state),

  //     .probe15(init_calib_complete),
  //     .probe16(read_request),
  //     .probe17(write_request),
  //     .probe18(read_response),
  //     .probe19(read_ready),

  //     .probe20(read_data),
  //     .probe21(write_data)
  // );


  /* Here we go... */
  mig_7series_0 ctl (
      .sys_clk_i(pclk),
      .sys_rst(rst),
      .ui_clk(sclk),

      .ddr2_dq(ddr2_dq),
      .ddr2_dqs_n(ddr2_dqs_n),
      .ddr2_dqs_p(ddr2_dqs_p),
      .ddr2_addr(ddr2_addr),
      .ddr2_ba(ddr2_ba),
      .ddr2_ras_n(ddr2_ras_n),
      .ddr2_cas_n(ddr2_cas_n),
      .ddr2_we_n(ddr2_we_n),
      .ddr2_ck_p(ddr2_ck_p),
      .ddr2_ck_n(ddr2_ck_n),
      .ddr2_cke(ddr2_cke),
      .ddr2_cs_n(ddr2_cs_n),
      .ddr2_dm(ddr2_dm),
      .ddr2_odt(ddr2_odt),

      .app_addr(app_addr),
      .app_cmd (app_cmd),
      .app_en  (app_en),

      .app_wdf_data(app_wdf_data),
      .app_wdf_end (app_wdf_end),
      .app_wdf_mask(app_wdf_mask),
      .app_wdf_wren(app_wdf_wren),

      .app_rd_data(app_rd_data),
      .app_rd_data_valid(app_rd_data_valid),
      .app_rd_data_end(app_rd_data_end),
      .init_calib_complete(init_calib_complete),

      .app_rdy(app_rdy),
      .app_wdf_rdy(app_wdf_rdy),

      .app_sr_req (1'b0),
      .app_ref_req(1'b0),
      .app_zq_req (1'b0)
  );

  /* No need to mask */
  assign app_wdf_mask = 16'b0;

  /* Two different state machines:
	 * - DISPATCH
	 * - READ
	 *
	 * We can batch requests generally, and they'll
	 * be ordered FIFO which is convenient for us.
	 *
	 * We're reading CACHE_BLOCK_BURSTS bursts, so our dispatch state
	 * machine should trip a flag to wait for that many bursts to come in
	 * and buffer the data as it happens. Write is easier - just fire on all
	 * cylinders and call it a night.
	 */
  logic [1:0] dispatch_state;
  logic read_active;

  logic [BURST_CTR_BITS-1:0] read_req_ctr, write_req_ctr, read_resp_ctr;
  // output logic [BURST_CTR_BITS-1:0] read_resp_ctr;

  /* Do some signals combinationally to save clocks in the dispatch
	 * state machine / head back to the idle state on the same
	 * clock cycle that done is asserted to the outside world
	 */
  assign read_ready = dispatch_state == `DISPATCH_IDLE && ~write_request && ~read_request;
  assign read_active = (dispatch_state == `DISPATCH_READ_SEND) || (dispatch_state == `DISPATCH_READ_WAIT);

  assign write_ready = read_ready;

  always_ff @(posedge sclk) begin : READ
    if (rst || !read_active) begin
      read_response <= 1'b0;
      read_resp_ctr <= {BURST_CTR_BITS{1'b0}};
      read_data <= {CACHE_BLOCK_BURSTS * BURST_BITS{1'b0}};
    end else if (app_rd_data_valid) begin
      if (read_resp_ctr == CACHE_BLOCK_BURSTS - 1) begin
        read_response <= 1'b1;
        read_resp_ctr <= {BURST_CTR_BITS{1'b0}};
      end else read_resp_ctr <= read_resp_ctr + 1;

      read_data[read_resp_ctr] <= app_rd_data;
    end
  end  /* READ */

  always_ff @(posedge sclk) begin : DISPATCH
    if (rst) begin
      dispatch_state <= `DISPATCH_IDLE;

      read_req_ctr <= {BURST_CTR_BITS{1'b0}};
      write_req_ctr <= {BURST_CTR_BITS{1'b0}};

      app_addr <= 27'b0;
      app_cmd <= `WRITE_CMD;
      app_en <= 1'b0;

      app_wdf_data <= 128'b0;
      app_wdf_end <= 1'b0;
      app_wdf_wren <= 1'b0;


    end else begin
      case (dispatch_state)
        `DISPATCH_IDLE: begin
          /* If a write request comes in, try and preflight the
				 * first write request and tell the write FSM to start
				 * receiving crap
				 */
          if (write_request) begin
            app_addr <= write_address;
            app_cmd <= `WRITE_CMD;
            app_en <= 1'b1;

            app_wdf_data <= write_data[0];
            app_wdf_end <= 1'b1;
            app_wdf_wren <= 1'b1;

            if (app_rdy && app_wdf_rdy) write_req_ctr <= {{BURST_CTR_BITS - 1{1'b0}}, 1'b1};
            dispatch_state <= `DISPATCH_WRITE_SEND;
          end				
				/* If a read request comes in, preflight the first
				 * read request if possible and trip the read FSM...
				 */
          else if (read_request) begin
            app_addr <= read_address;
            app_cmd <= `READ_CMD;
            app_en <= 1'b1;

            app_wdf_wren <= 1'b0;

            if (app_rdy) read_req_ctr <= {{BURST_CTR_BITS - 1{1'b0}}, 1'b1};
            dispatch_state <= `DISPATCH_READ_SEND;

          end else begin
            app_en <= 1'b0;
            app_wdf_wren <= 1'b0;
          end
        end

        `DISPATCH_WRITE_SEND: begin
          /* If we've fired off all the requests there are to
				 * fire off slash we're currently firing the last one,
				 * jump back to idle and let the user know that we can
				 * accept a new write request
				 */
          if (app_rdy && app_wdf_rdy) begin
            /* yep, we are in fact done */
            if (write_req_ctr == CACHE_BLOCK_BURSTS - 1) begin
              write_req_ctr  <= {BURST_CTR_BITS{1'b0}};
              dispatch_state <= `DISPATCH_IDLE;
            end else write_req_ctr <= write_req_ctr + 1;
          end

          /* either way, send the appropriate bits */
          app_addr <= write_address + 8 * write_req_ctr;
          app_cmd <= `WRITE_CMD;
          app_en <= 1'b1;

          app_wdf_data <= write_data[write_req_ctr];
          app_wdf_end <= 1'b1;
          app_wdf_wren <= 1'b1;
        end

        `DISPATCH_READ_SEND: begin
          /* are we done? same deal as with the write
				 * side of things, just warp to an idle state
				 * until done
				 */
          if (app_rdy) begin
            /* are we done? same deal as before, this condition
					 * is just a bit trickier. assume that there's at least
					 * a single cycle of latency between the last read command
					 * and the last read output
					 */
            if (read_req_ctr == CACHE_BLOCK_BURSTS - 1) begin
              read_req_ctr   <= {BURST_CTR_BITS{1'b0}};
              dispatch_state <= `DISPATCH_READ_WAIT;
            end else read_req_ctr <= read_req_ctr + 1'b1;
          end

          /* either way, try to issue */
          app_addr <= read_address + 8 * read_req_ctr;
          app_cmd <= `READ_CMD;
          app_en <= 1'b1;

          app_wdf_wren <= 1'b0;
        end

        `DISPATCH_READ_WAIT: begin
          app_en <= 1'b0;
          app_wdf_wren <= 1'b0;

          if (read_resp_ctr == CACHE_BLOCK_BURSTS - 1 && (app_rd_data_valid)) //app_rd_data_end)// && app_rd_data_valid)
            dispatch_state <= `DISPATCH_IDLE;
        end
      endcase
    end
  end  /* DISPATCH */


endmodule