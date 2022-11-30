`default_nettype none
// 
`timescale 1ns / 1ps
/* 4:1 data rate + DDR => 16 * 8 = 128 */
`define BURST_BITS 128 // = 16 bits a hword * 8 hwords a burst
`define CACHE_BLOCK_BYTES 64 // 2 bytes a hword * 8 hwords a burst * 4 hwords in cache
`define CACHE_BLOCK_BITS `CACHE_BLOCK_BYTES * 8
`define CACHE_BLOCK_BURSTS `CACHE_BLOCK_BITS / `BURST_BITS
`define BURST_CTR_BITS $clog2(`CACHE_BLOCK_BURSTS)
`define DRAM_ADDR_BITS 27
`define FRAME_WIDTH 1024
`define FRAME_HEIGHT 768
`define COLOR_WIDTH 12
`define FRAME_WIDTH_BITS 11
`define FRAME_HEIGHT_BITS 11
`define MAX_HCOUNT 1344
//$clog2(`FRAME_WIDTH)
//$clog2(`FRAME_HEIGHT)
module top_level (
    input wire clk_100mhz,
    input wire [15:0] sw,
    input wire btnc,
    input wire btnu,
    input wire btnl,
    input wire btnr,
    input wire btnd,
    output logic [7:0] an,
    output logic caa,
    cab,
    cac,
    cad,
    cae,
    caf,
    cag,

    output wire [15:0] led,

    output logic [12:0] ddr2_addr,
    output logic [2:0] ddr2_ba,
    output logic ddr2_ras_n,
    ddr2_cas_n,
    output logic ddr2_we_n,
    output logic ddr2_ck_p,
    ddr2_ck_n,
    ddr2_cke,
    output logic ddr2_cs_n,
    output logic [1:0] ddr2_dm,
    output logic ddr2_odt,
    inout wire [15:0] ddr2_dq,
    inout wire [1:0] ddr2_dqs_n,
    inout wire [1:0] ddr2_dqs_p,

    output logic [3:0] vga_r,
    vga_g,
    vga_b,
    output logic vga_hs,
    vga_vs

);

  logic dram_init_complete;

  logic sys_rst, sys_clk, clk_200mhz, dram_ui_clk, clk_65mhz, pix_clk;

  logic dram_read_rq, dram_read_rq_ui_clk, dram_write_rq, dram_write_rq_ui_clk;
  logic dram_read_rdy_ui_clk, dram_write_rdy_ui_clk, dram_read_rdy, dram_write_rdy;
  logic dram_read_valid, dram_read_valid_ui_clk;
  logic [1:0] dram_dispatch_state;

  logic [`DRAM_ADDR_BITS-1:0]
      dram_read_addr, dram_read_addr_ui_clk, dram_write_addr, dram_write_addr_ui_clk;
  logic [`CACHE_BLOCK_BURSTS-1:0][`BURST_BITS-1:0]
      dram_read_data, dram_read_data_ui_clk, dram_write_data, dram_write_data_ui_clk;

  //vga module generation signals:
  logic [`FRAME_WIDTH_BITS-1:0] hcount_pix_clk, hcount;  // pixel on current line
  logic [`FRAME_HEIGHT_BITS-1:0] vcount_pix_clk, vcount;  // line number
  logic hsync, vsync, blank, vga_pause;  //control signals for vga

  assign sys_rst = btnc;

  clk_divider clk_div (
      .reset(sys_rst),
      .clk_in_100(clk_100mhz),
      .clk_out_200(clk_200mhz),
      .clk_out_65(clk_65mhz)
  );

  assign sys_clk = clk_200mhz;
  assign pix_clk = clk_65mhz;

  vga vga_gen (
      .rst(sys_rst),
      .pixel_clk_in(pix_clk),
      .hcount_out(hcount_pix_clk),
      .vcount_out(vcount_pix_clk),
      .pause(1'b0),
      .hsync_out(hsync),
      .vsync_out(vsync),
      .blank_out(blank)
  );

  // cdc_pipe #(
  //     .DATA_WIDTH(512)
  // ) read_data_cdc (
  //     .rst(sys_rst),
  //     .src_clk(dram_ui_clk),
  //     .dest_clk(sys_clk),
  //     .input_signal_src_clk(dram_read_data_ui_clk),
  //     .output_signal_dest_clk(dram_read_data)
  // );

  cdc_bram_bridge_512 read_data_cdc (
      .wea(1'b1),  // input wire [0 : 0] wea
      .clka(dram_ui_clk),  // input wire clka
      .clkb(sys_clk),  // input wire clkb
      .addra(1'b0),  // input wire [0 : 0] addra
      .addrb(1'b0),  // input wire [0 : 0] addrb
      .dina(dram_read_data_ui_clk),  // input wire [511 : 0] dina
      .doutb(dram_read_data)  // output wire [511 : 0] doutb
  );

  // cdc_pipe read_rdy_cdc (
  //     .rst(sys_rst),
  //     .src_clk(dram_ui_clk),
  //     .dest_clk(sys_clk),
  //     .input_signal_src_clk(dram_read_rdy_ui_clk),
  //     .output_signal_dest_clk(dram_read_rdy)
  // );

  // cdc_pipe write_rdy_cdc (
  //     .rst(sys_rst),
  //     .src_clk(dram_ui_clk),
  //     .dest_clk(sys_clk),
  //     .input_signal_src_clk(dram_write_rdy_ui_clk),
  //     .output_signal_dest_clk(dram_write_rdy)
  // );

  cdc_bram_bridge_1 read_rdy_cdc (
      .wea(1'b1),  // input wire [0 : 0] wea
      .clka(dram_ui_clk),  // input wire clka
      .clkb(sys_clk),  // input wire clkb
      .addra(1'b0),  // input wire [0 : 0] addra
      .addrb(1'b0),  // input wire [0 : 0] addrb
      .dina(dram_read_rdy_ui_clk),  // input wire [511 : 0] dina
      .doutb(dram_read_rdy)  // output wire [511 : 0] doutb
  );

  cdc_bram_bridge_1 write_rdy_cdc (
      .wea(1'b1),  // input wire [0 : 0] wea
      .clka(dram_ui_clk),  // input wire clka
      .clkb(sys_clk),  // input wire clkb
      .addra(1'b0),  // input wire [0 : 0] addra
      .addrb(1'b0),  // input wire [0 : 0] addrb
      .dina(dram_write_rdy_ui_clk),  // input wire [511 : 0] dina
      .doutb(dram_write_rdy)  // output wire [511 : 0] doutb
  );

  // cdc_pipe read_valid_cdc (
  //     .rst(sys_rst),
  //     .src_clk(dram_ui_clk),
  //     .dest_clk(sys_clk),
  //     .input_signal_src_clk(dram_read_valid_ui_clk),
  //     .output_signal_dest_clk(dram_read_valid)
  // );

  cdc_bram_bridge_1 read_valid_cdc (
      .wea(1'b1),  // input wire [0 : 0] wea
      .clka(dram_ui_clk),  // input wire clka
      .clkb(sys_clk),  // input wire clkb
      .addra(1'b0),  // input wire [0 : 0] addra
      .addrb(1'b0),  // input wire [0 : 0] addrb
      .dina(dram_read_valid_ui_clk),  // input wire [511 : 0] dina
      .doutb(dram_read_valid)  // output wire [511 : 0] doutb
  );

  // cdc_pulse read_rq_cdc (
  //     .rst(sys_rst),
  //     .src_clk(sys_clk),
  //     .dest_clk(dram_ui_clk),
  //     .input_signal_src_clk(dram_read_rq),
  //     .output_signal_dest_clk(dram_read_rq_ui_clk)
  // );

  // cdc_pulse write_rq_cdc (
  //     .rst(sys_rst),
  //     .src_clk(sys_clk),
  //     .dest_clk(dram_ui_clk),
  //     .input_signal_src_clk(dram_write_rq),
  //     .output_signal_dest_clk(dram_write_rq_ui_clk)
  // );

  cdc_bram_bridge_1 read_rq_cdc (
      .wea(1'b1),  // input wire [0 : 0] wea
      .clka(sys_clk),  // input wire clka
      .clkb(dram_ui_clk),  // input wire clkb
      .addra(1'b0),  // input wire [0 : 0] addra
      .addrb(1'b0),  // input wire [0 : 0] addrb
      .dina(dram_read_rq),  // input wire [511 : 0] dina
      .doutb(dram_read_rq_ui_clk)  // output wire [511 : 0] doutb
  );

  // logic sys_rst_pix_clk, sys_rst_dui_clk;

  // cdc_bram_bridge_1 pix_clk_rst_cdc (
  //     .wea(1'b1),  // input wire [0 : 0] wea
  //     .clka(sys_clk),  // input wire clka
  //     .clkb(pix_clk),  // input wire clkb
  //     .addra(1'b0),  // input wire [0 : 0] addra
  //     .addrb(1'b0),  // input wire [0 : 0] addrb
  //     .dina(sys_rst),  // input wire [511 : 0] dina
  //     .doutb(sys_rst_pix_clk)  // output wire [511 : 0] doutb
  // );

  // cdc_bram_bridge_1 dui_clk_rst_cdc (
  //     .wea(1'b1),  // input wire [0 : 0] wea
  //     .clka(sys_clk),  // input wire clka
  //     .clkb(dram_ui_clk),  // input wire clkb
  //     .addra(1'b0),  // input wire [0 : 0] addra
  //     .addrb(1'b0),  // input wire [0 : 0] addrb
  //     .dina(sys_rst),  // input wire [511 : 0] dina
  //     .doutb(sys_rst_dui_clk)  // output wire [511 : 0] doutb
  // );


  cdc_bram_bridge_1 write_rq_cdc (
      .wea(1'b1),  // input wire [0 : 0] wea
      .clka(sys_clk),  // input wire clka
      .clkb(dram_ui_clk),  // input wire clkb
      .addra(1'b0),  // input wire [0 : 0] addra
      .addrb(1'b0),  // input wire [0 : 0] addrb
      .dina(dram_write_rq),  // input wire [511 : 0] dina
      .doutb(dram_write_rq_ui_clk)  // output wire [511 : 0] doutb
  );

  // let current = the one im writing to
  cdc_bram_bridge_512 write_data_cdc (
      .wea(1'b1),  // input wire [0 : 0] wea
      .clka(sys_clk),  // input wire clka
      .clkb(dram_ui_clk),  // input wire clkb
      .addra(1'b0),  // input wire [0 : 0] addra
      .addrb(1'b0),  // input wire [0 : 0] addrb
      .dina(dram_write_data),  // input wire [511 : 0] dina
      .doutb(dram_write_data_ui_clk)  // output wire [511 : 0] doutb
  );

  cdc_bram_bridge_27 write_addr_cdc (
      .wea(1'b1),  // input wire [0 : 0] wea
      .clka(sys_clk),  // input wire clka
      .clkb(dram_ui_clk),  // input wire clkb
      .addra(1'b0),  // input wire [0 : 0] addra
      .addrb(1'b0),  // input wire [0 : 0] addrb
      .dina(dram_write_addr),  // input wire [511 : 0] dina
      .doutb(dram_write_addr_ui_clk)  // output wire [511 : 0] doutb
  );

  cdc_bram_bridge_27 read_addr_cdc (
      .wea(1'b1),  // input wire [0 : 0] wea
      .clka(sys_clk),  // input wire clka
      .clkb(dram_ui_clk),  // input wire clkb
      .addra(1'b0),  // input wire [0 : 0] addra
      .addrb(1'b0),  // input wire [0 : 0] addrb
      .dina(dram_read_addr),  // input wire [511 : 0] dina
      .doutb(dram_read_addr_ui_clk)  // output wire [511 : 0] doutb
  );

  logic [`DRAM_ADDR_BITS-1:0] pixel_addr_pix_clk_sys_clk;

  cdc_bram_bridge_27 papcsc_cdc (
      .wea(1'b1),  // input wire [0 : 0] wea
      .clka(pix_clk),  // input wire clka
      .clkb(sys_clk),  // input wire clkb
      .addra(1'b0),  // input wire [0 : 0] addra
      .addrb(1'b0),  // input wire [0 : 0] addrb
      .dina(pixel_addr_pix_clk),  // input wire [511 : 0] dina
      .doutb(pixel_addr_pix_clk_sys_clk)  // output wire [511 : 0] doutb
  );

  cdc_bram_bridge_27 npatr_cdc (
      .wea(1'b1),  // input wire [0 : 0] wea
      .clka(pix_clk),  // input wire clka
      .clkb(sys_clk),  // input wire clkb
      .addra(1'b0),  // input wire [0 : 0] addra
      .addrb(1'b0),  // input wire [0 : 0] addrb
      .dina(next_pix_addr_to_read_pix_clk),  // input wire [511 : 0] dina
      .doutb(next_pix_addr_to_read)  // output wire [511 : 0] doutb
  );

  cdc_bram_bridge_512 prb_cdc (
      .wea(1'b1),  // input wire [0 : 0] wea
      .clka(sys_clk),  // input wire clka
      .clkb(pix_clk),  // input wire 
      .addra(current_inner_pixel_read_buffer),  // input wire [0 : 0] addra
      .addrb(~current_inner_pixel_read_buffer_pix_clk),  // input wire [0 : 0] addrb
      .dina(pixel_read_buffer),  // input wire [511 : 0] dina
      .doutb(pixel_read_buffer_pix_clk)  // output wire [511 : 0] doutb
  );

  cdc_bram_bridge_1 ciprb_cdc (
      .wea(1'b1),  // input wire [0 : 0] wea
      .clka(pix_clk),  // input wire clka
      .clkb(sys_clk),  // input wire clkb
      .addra(1'b0),  // input wire [0 : 0] addra
      .addrb(1'b0),  // input wire [0 : 0] addrb
      .dina(current_inner_pixel_read_buffer_pix_clk),  // input wire [511 : 0] dina
      .doutb(current_inner_pixel_read_buffer)  // output wire [511 : 0] doutb
  );

  // cdc_bram_bridge_1 cidwdb_cdc (
  //     .wea(1'b1),  // input wire [0 : 0] wea
  //     .clka(sys_clk),  // input wire clka
  //     .clkb(dram_ui_clk),  // input wire clkb
  //     .addra(1'b0),  // input wire [0 : 0] addra
  //     .addrb(1'b0),  // input wire [0 : 0] addrb
  //     .dina(current_inner_dram_write_data_buffer),  // input wire [511 : 0] dina
  //     .doutb(current_inner_dram_write_data_buffer_dui_clk)  // output wire [511 : 0] doutb
  // );

  // cdc_pipe ciprb_cdc (
  //     .rst(sys_rst),
  //     .src_clk(pix_clk),
  //     .dest_clk(sys_clk),
  //     .input_signal_src_clk(current_inner_pixel_read_buffer_pix_clk),
  //     .output_signal_dest_clk(current_inner_pixel_read_buffer)
  // );

  cdc_bram_bridge_5 prba_cdc (
      .wea(1'b1),  // input wire [0 : 0] wea
      .clka(pix_clk),  // input wire clka
      .clkb(sys_clk),  // input wire clkb
      .addra(1'b0),  // input wire [0 : 0] addra
      .addrb(1'b0),  // input wire [0 : 0] addrb
      .dina(pixel_read_buffer_addr_pix_clk),  // input wire [511 : 0] dina
      .doutb(pixel_read_buffer_addr)  // output wire [511 : 0] doutb
  );

  // cdc_pipe #(.DATA_WIDTH(5)) prba_cdc (
  //     .rst(sys_rst),
  //     .src_clk(pix_clk),
  //     .dest_clk(sys_clk),
  //     .input_signal_src_clk(pixel_read_buffer_addr_pix_clk),
  //     .output_signal_dest_clk(pixel_read_buffer_addr)
  // );

  logic
      // current_inner_dram_write_data_buffer,
      // current_inner_dram_write_data_buffer_dui_clk,
      current_inner_dram_read_addr_buffer,
      current_inner_pixel_read_buffer_pix_clk,
      current_inner_pixel_read_buffer;
  // current_inner_dram_write_addr_buffer;

  logic [`COLOR_WIDTH-1:0] vga_pixel;

  button bu (
      .clk(sys_clk),
      .rst(sys_rst),
      .raw_in(btnu),
      .pulse_out(p_btnu),
      .clean_out(c_btnu)
  );
  button bd (
      .clk(sys_clk),
      .rst(sys_rst),
      .raw_in(btnd),
      .pulse_out(p_btnd),
      .clean_out(c_btnd)
  );
  button bl (
      .clk(sys_clk),
      .rst(sys_rst),
      .raw_in(btnl),
      .pulse_out(p_btnl),
      .clean_out(c_btnl)
  );
  button br (
      .clk(sys_clk),
      .rst(sys_rst),
      .raw_in(btnr),
      .pulse_out(p_btnr),
      .clean_out(c_btnr)
  );
  button bc (
      .clk(sys_clk),
      .rst(sys_rst),
      .raw_in(btnc),
      .pulse_out(p_btnc),
      .clean_out(c_btnc)
  );

  logic [3:0] state;

  logic p_btnu, p_btnd, p_btnl, p_btnr, p_btnc, reading;
  logic c_btnu, c_btnd, c_btnl, c_btnr, c_btnc;


  assign led[0] = dram_init_complete;
  // logic [2:0][1:0][`FRAME_WIDTH_BITS:0] triangle1, triangle2, triangle3;
  // logic [`COLOR_WIDTH-1:0] triangle_color, frame_buffer_out;
  // logic valid_triangle_color;
  logic app_rd_data_valid;
  logic [`BURST_CTR_BITS-1:0] read_resp_ctr;
  // logic is_within;

  dram #(
      .BURST_BITS(`BURST_BITS),
      .CACHE_BLOCK_BYTES(`CACHE_BLOCK_BYTES),
      .DRAM_ADDR_BITS(`DRAM_ADDR_BITS)
  ) my_dram (
      .pclk(sys_clk),
      .rst(sys_rst),
      .sclk(dram_ui_clk),
      .read_ready(dram_read_rdy_ui_clk),
      .read_request(dram_read_rq_ui_clk),
      .read_address(dram_read_addr_ui_clk),
      .read_response(dram_read_valid_ui_clk),
      .read_data(dram_read_data_ui_clk),
      .write_ready(dram_write_rdy_ui_clk),
      .write_request(dram_write_rq_ui_clk),
      .write_address(dram_write_addr_ui_clk),
      .write_data(dram_write_data_ui_clk),

      .init_calib_complete(dram_init_complete),
      .dispatch_state(dram_dispatch_state),
      .read_resp_ctr(read_resp_ctr),
      .app_rd_data_valid(app_rd_data_valid),

      /* DDR output signals strung straight to the top level */
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
      .ddr2_dq(ddr2_dq),
      .ddr2_dqs_p(ddr2_dqs_p),
      .ddr2_dqs_n(ddr2_dqs_n)
  );

  // triangle_fill tfill (
  //     .clk(sys_clk),
  //     .hcount(hcount),
  //     .vcount(vcount),
  //     .triangle(triangle1),
  //     .is_within(is_within)
  // );

  // assign triangle_color = 12'hfff;
  // assign valid_triangle_color = is_within;

  logic [1:0] current_pixel_buffer;
  logic [31:0][15:0]
      pixel_read_buffer,
      pixel_read_buffer_pix_clk,
      pixel_read_buffer_0,
      pixel_read_buffer_1,
      pixel_read_buffer_0_pix_clk,
      pixel_read_buffer_1_pix_clk;
  logic [4:0] pixel_read_buffer_addr, pixel_read_buffer_addr_pix_clk;
  logic [4:0] pixel_write_buffer_addr;


  logic [`DRAM_ADDR_BITS-1:0]
      pixel_addr, pixel_addr_pix_clk, next_pix_addr_to_read_pix_clk, next_pix_addr_to_read;

  logic [31:0][15:0] pixel_write_buffer;

  // assign led[4:0] = pixel_read_buffer_addr;
  // assign led[5] = pixel_read_buffer_addr == 'd31;

  // ila_0 ila (
  //     .clk(sys_clk),
  //     .probe0(pixel_addr),
  //     .probe1(pixel_addr_pix_clk),

  //     .probe2(vcount),
  //     .probe3(hcount),

  //     .probe4(vcount_pix_clk),
  //     .probe5(hcount_pix_clk),

  //     .probe6(pixel_write_buffer_addr),
  //     .probe7(pixel_read_buffer_addr),

  //     .probe8(dram_read_rdy),
  //     .probe9(dram_write_rdy),

  //     .probe10(dram_read_rq),
  //     .probe11(dram_write_rq),

  //     .probe12(dram_read_rdy_ui_clk),
  //     .probe13(dram_write_rdy_ui_clk),
  //     .probe14(dram_read_rq_ui_clk),
  //     .probe15(dram_write_rq_ui_clk),

  //     .probe16(dram_dispatch_state),
  //     .probe17(dram_ui_clk),

  //     .probe18(read_resp_ctr),
  //     .probe19(app_rd_data_valid)
  // );

  assign pixel_addr = `FRAME_WIDTH * vcount + hcount;
  assign pixel_addr_pix_clk = `FRAME_WIDTH * vcount_pix_clk + hcount_pix_clk;

  // always_comb begin
  //   if (sys_rst) begin
  //     vga_pause = 0;
  //   end else begin
  //     if ((pixel_read_buffer_addr == 'b0) && !dram_read_rdy) begin
  //       vga_pause = 1 && !sw[1];
  //     end else begin
  //       vga_pause = sw[0];
  //     end
  //   end
  // end

  always_ff @(posedge pix_clk) begin
    if (sys_rst) begin
      vga_pixel = 0;
      pixel_read_buffer_addr_pix_clk <= 0;
      current_inner_pixel_read_buffer_pix_clk <= 0;
    end else begin

      if ((vcount_pix_clk < `FRAME_HEIGHT) && (hcount_pix_clk < `FRAME_WIDTH)) begin
        pixel_read_buffer_addr_pix_clk <= pixel_read_buffer_addr_pix_clk + 1;

        if (pixel_read_buffer_addr_pix_clk == 'd31) begin
          current_inner_pixel_read_buffer_pix_clk <= ~current_inner_pixel_read_buffer_pix_clk;
        end else if (pixel_read_buffer_addr_pix_clk == 0) begin
          next_pix_addr_to_read_pix_clk <= pixel_addr_pix_clk + 32;
        end
      end


      if (pixel_read_buffer_addr_pix_clk == 0) begin
        vga_pixel = 12'hf00;
      end else if ((vcount_pix_clk == 512) && (pixel_read_buffer_addr_pix_clk < 16)) begin
        vga_pixel = 12'h0f0;
      end else begin
        vga_pixel = pixel_read_buffer_pix_clk[pixel_read_buffer_addr_pix_clk];
      end
    end
  end

  assign led[15] = dram_read_rdy;
  assign led[14] = dram_write_rdy;

  assign led[10] = dram_read_rq;
  assign led[9]  = dram_write_rq;

  assign led[12] = dram_ui_clk;

  logic [`DRAM_ADDR_BITS-1:0] initial_dram_addr;
  logic [15:0] current_pixel;


  always_comb begin
    if (sys_rst) begin
      current_pixel = 0;
    end else begin
      if ((vcount > 600) && (vcount < 700)) begin
        current_pixel = 16'h0f0f;
      end else if ((hcount > 400) && (hcount < 500) && (vcount > 400) && (vcount < 500)) begin
        current_pixel = 16'h000f;
      end else begin
        current_pixel = 16'h0ff0;
      end
    end
  end

  always_ff @(posedge sys_clk) begin
    if (sys_rst) begin
      // triangle1[0] <= {11'd500, 11'd500};
      // triangle1[1] <= {11'd600, 11'd500};
      // triangle1[2] <= {11'd500, 11'd600};

      dram_read_rq <= 0;
      dram_write_rq <= 0;

      dram_write_addr <= 0;
      dram_read_addr <= 0;

      pixel_write_buffer_addr <= 0;
      pixel_write_buffer <= 0;

      pixel_read_buffer <= 0;
      initial_dram_addr <= 0;


      // current_inner_dram_write_addr_buffer <= 0;
      // current_inner_dram_write_data_buffer <= 0;

      hcount <= 0;
      vcount <= 0;

    end else begin
      if (pixel_write_buffer_addr != 'd31 || dram_write_rdy) begin
        if (hcount == `FRAME_WIDTH - 1) begin
          hcount <= 0;
          if (vcount == `FRAME_HEIGHT - 1) begin
            vcount <= 0;
          end else begin
            vcount <= vcount + 1;
          end
        end else begin
          hcount <= hcount + 1;
        end

        if (pixel_write_buffer_addr == 'b0) begin
          initial_dram_addr <= pixel_addr;
        end

        pixel_write_buffer_addr <= pixel_write_buffer_addr + 1;

        // if ((vcount > 600) && (vcount < 700)) begin
        //   current_pixel = 16'h0f0f;
        //   // pixel_write_buffer[pixel_write_buffer_addr] <= ;
        // end else if ((hcount > 400) && (hcount < 500) && (vcount > 400) && (vcount < 500)) begin
        //   current_pixel = 16'h000f;
        //   // pixel_write_buffer[pixel_write_buffer_addr] <= ;
        // end else begin
        //   current_pixel = 16'h0ff0;
        //   // pixel_write_buffer[pixel_write_buffer_addr] <= ;
        // end

        pixel_write_buffer[pixel_write_buffer_addr] <= current_pixel;

        if (pixel_write_buffer_addr == 'd31) begin
          dram_write_data <= {current_pixel, pixel_write_buffer[30:0]};
          dram_write_addr <= initial_dram_addr;

          dram_write_rq   <= 1;
        end else begin
          dram_write_rq <= 0;
        end
      end else begin
        dram_write_rq <= 0;
      end


      if (pixel_read_buffer_addr == 'b0) begin
        if (dram_read_rdy) begin
          dram_read_addr <= next_pix_addr_to_read;  //pixel_addr_pix_clk_sys_clk + 32;
          dram_read_rq   <= 1;
        end else begin
          dram_read_rq <= 0;
        end
      end else begin
        dram_read_rq <= 0;
      end

      if (dram_read_valid) begin
        pixel_read_buffer <= dram_read_data;
      end

    end
  end

  assign vga_r  = ~blank ? vga_pixel[11:8] : 0;
  assign vga_g  = ~blank ? vga_pixel[7:4] : 0;
  assign vga_b  = ~blank ? vga_pixel[3:0] : 0;

  assign vga_hs = ~hsync;
  assign vga_vs = ~vsync;

endmodule
`default_nettype wire
