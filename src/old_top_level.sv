`default_nettype none
// 
`timescale 1ns / 1ps
/* 4:1 data rate + DDR => 16 * 8 = 128 */
`define BURST_BITS 128 // = 16 bits a hword * 8 hwords a burst
`define CACHE_BLOCK_BYTES 512 // 2 bytes a hword * 8 hwords a burst * 4 hwords in cache
`define CACHE_BLOCK_BITS `CACHE_BLOCK_BYTES * 8
`define CACHE_BLOCK_BURSTS `CACHE_BLOCK_BITS / `BURST_BITS
`define BURST_CTR_BITS $clog2(`CACHE_BLOCK_BURSTS)
`define PIXEL_BUFFER_SIZE `CACHE_BLOCK_BITS / 16
`define PIXEL_BUFFER_ADDR_BITS $clog2(`PIXEL_BUFFER_SIZE)
`define DRAM_ADDR_BITS 27
`define FRAME_WIDTH 1024
`define FRAME_HEIGHT 768
`define COLOR_WIDTH 12
`define FRAME_WIDTH_BITS 11
`define FRAME_HEIGHT_BITS 11
`define MAX_HCOUNT 1344

module old_top_level (
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

  logic dram_init_complete, dram_init_complete_pix_clk, dram_init_complete_dui_clk;

  logic sys_rst, sys_clk, clk_200mhz, dram_ui_clk, clk_65mhz, pix_clk;

  logic
      dram_read_rq, dram_read_rq_pix_clk, dram_read_rq_ui_clk, dram_write_rq, dram_write_rq_ui_clk;
  logic
      dram_read_rdy_pix_clk,
      dram_read_rdy_ui_clk,
      dram_write_rdy_ui_clk,
      dram_read_rdy,
      dram_write_rdy;
  logic dram_read_valid, dram_read_valid_pix_clk, dram_read_valid_ui_clk;

  logic [1:0] dram_dispatch_state_ui_clk;

  logic [`DRAM_ADDR_BITS-1:0] dram_read_addr_pix_clk, dram_read_addr_ui_clk;
  logic [`DRAM_ADDR_BITS-1:0] dram_write_addr, dram_write_addr_ui_clk;

  logic [`CACHE_BLOCK_BITS-1:0] dram_read_data_ui_clk, dram_read_data_pix_clk;
  logic [`CACHE_BLOCK_BITS-1:0] dram_write_data, dram_write_data_ui_clk;

  //vga module generation signals:
  logic [`FRAME_WIDTH_BITS-1:0]
      hcount_pix_clk,
      hcount,
      hcount_dui_clk_pix_clk,
      hcount_dui_clk_sys_clk;  // pixel on current line
  logic [`FRAME_HEIGHT_BITS-1:0]
      vcount_pix_clk, vcount, vcount_dui_clk_pix_clk, vcount_dui_clk_sys_clk;  // line number
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
      .pause(~dram_init_complete_pix_clk),
      .hsync_out(hsync),
      .vsync_out(vsync),
      .blank_out(blank)
  );

  cdc_bram_bridge_1024 read_data_pc_cdc (
      .wea  (1'b1),
      .clka (dram_ui_clk),
      .clkb (pix_clk),
      .addra(1'b0),
      .addrb(1'b0),
      .dina (dram_read_data_ui_clk),
      .doutb(dram_read_data_pix_clk)
  );

  cdc_bram_bridge_1 read_rdy_pc_cdc (
      .wea  (1'b1),
      .clka (dram_ui_clk),
      .clkb (pix_clk),
      .addra(1'b0),
      .addrb(1'b0),
      .dina (dram_read_rdy_ui_clk),
      .doutb(dram_read_rdy_pix_clk)
  );

  cdc_bram_bridge_1 dinit_pix_cdc (
      .wea  (1'b1),
      .clka (dram_ui_clk),
      .clkb (pix_clk),
      .addra(1'b0),
      .addrb(1'b0),
      .dina (dram_init_complete_dui_clk),
      .doutb(dram_init_complete_pix_clk)
  );

  cdc_bram_bridge_1 dinit_cdc (
      .wea  (1'b1),
      .clka (dram_ui_clk),
      .clkb (sys_clk),
      .addra(1'b0),
      .addrb(1'b0),
      .dina (dram_init_complete_dui_clk),
      .doutb(dram_init_complete)
  );

  cdc_bram_bridge_1 write_rdy_cdc (
      .wea  (1'b1),
      .clka (dram_ui_clk),
      .clkb (sys_clk),
      .addra(1'b0),
      .addrb(1'b0),
      .dina (dram_write_rdy_ui_clk),
      .doutb(dram_write_rdy)
  );

  cdc_bram_bridge_1 read_valid_pc_cdc (
      .wea  (1'b1),
      .clka (dram_ui_clk),
      .clkb (pix_clk),
      .addra(1'b0),
      .addrb(1'b0),
      .dina (dram_read_valid_ui_clk),
      .doutb(dram_read_valid_pix_clk)
  );

  cdc_bram_bridge_1 read_rq_pc_cdc (
      .wea  (1'b1),
      .clka (pix_clk),
      .clkb (dram_ui_clk),
      .addra(1'b0),
      .addrb(1'b0),
      .dina (dram_read_rq_pix_clk),
      .doutb(dram_read_rq_ui_clk)
  );

  cdc_bram_bridge_1 write_rq_cdc (
      .wea  (1'b1),
      .clka (sys_clk),
      .clkb (dram_ui_clk),
      .addra(1'b0),
      .addrb(1'b0),
      .dina (dram_write_rq),
      .doutb(dram_write_rq_ui_clk)
  );

  cdc_bram_bridge_1024 write_data_cdc (
      .wea  (1'b1),
      .clka (sys_clk),
      .clkb (dram_ui_clk),
      .addra(1'b0),
      .addrb(1'b0),
      .dina (dram_write_data),
      .doutb(dram_write_data_ui_clk)
  );

  cdc_bram_bridge_27 write_addr_cdc (
      .wea  (1'b1),
      .clka (sys_clk),
      .clkb (dram_ui_clk),
      .addra(1'b0),
      .addrb(1'b0),
      .dina (dram_write_addr),
      .doutb(dram_write_addr_ui_clk)
  );

  cdc_bram_bridge_27 read_addr_pc_cdc (
      .wea  (1'b1),
      .clka (pix_clk),
      .clkb (dram_ui_clk),
      .addra(1'b0),
      .addrb(1'b0),
      .dina (dram_read_addr_pix_clk),
      .doutb(dram_read_addr_ui_clk)
  );

  cdc_bram_bridge_11 hcs_cdc (
      .wea  (1'b1),
      .clka (sys_clk),
      .clkb (dram_ui_clk),
      .addra(1'b0),
      .addrb(1'b0),
      .dina (hcount),
      .doutb(hcount_dui_clk_sys_clk)
  );

  cdc_bram_bridge_11 hcp_cdc (
      .wea  (1'b1),
      .clka (pix_clk),
      .clkb (dram_ui_clk),
      .addra(1'b0),
      .addrb(1'b0),
      .dina (hcount_pix_clk),
      .doutb(hcount_dui_clk_pix_clk)
  );

  cdc_bram_bridge_11 vcs_cdc (
      .wea  (1'b1),
      .clka (sys_clk),
      .clkb (dram_ui_clk),
      .addra(1'b0),
      .addrb(1'b0),
      .dina (vcount),
      .doutb(vcount_dui_clk_sys_clk)
  );

  cdc_bram_bridge_11 vcp_cdc (
      .wea  (1'b1),
      .clka (pix_clk),
      .clkb (dram_ui_clk),
      .addra(1'b0),
      .addrb(1'b0),
      .dina (vcount_pix_clk),
      .doutb(vcount_dui_clk_pix_clk)
  );

  logic current_inner_pixel_read_buffer_pix_clk;
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

  logic p_btnu, p_btnd, p_btnl, p_btnr, p_btnc;
  logic c_btnu, c_btnd, c_btnl, c_btnr, c_btnc;

  assign led[0] = dram_init_complete;

  logic app_rd_data_valid_ui_clk;
  logic [`BURST_CTR_BITS-1:0] read_resp_ctr_ui_clk;

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
      .init_calib_complete(dram_init_complete_dui_clk),

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

  logic [`PIXEL_BUFFER_ADDR_BITS-1:0] pixel_read_buffer_addr, pixel_read_buffer_addr_pix_clk;
  logic [`PIXEL_BUFFER_ADDR_BITS-1:0] pixel_write_buffer_addr;

  logic [1:0][`PIXEL_BUFFER_SIZE-1:0][15:0] pixel_read_buffer_pix_clk;

  logic [`DRAM_ADDR_BITS-1:0] pixel_addr, pixel_addr_pix_clk;

  logic [`PIXEL_BUFFER_SIZE-1:0][15:0] pixel_write_buffer;

  assign pixel_addr = `FRAME_WIDTH * vcount + hcount;
  assign pixel_addr_pix_clk = `FRAME_WIDTH * vcount_pix_clk + hcount_pix_clk;


  always_comb begin
    if (sys_rst) begin
      vga_pixel = 0;
    end else begin
      if (pixel_read_buffer_addr_pix_clk == 0) begin
        vga_pixel = 12'hf00;
      end else begin
        vga_pixel = pixel_read_buffer_pix_clk[~current_inner_pixel_read_buffer_pix_clk][pixel_read_buffer_addr_pix_clk];
      end
    end
  end

  always_ff @(posedge pix_clk) begin
    if (sys_rst) begin
      pixel_read_buffer_addr_pix_clk <= 0;
      current_inner_pixel_read_buffer_pix_clk <= 0;
      dram_read_rq_pix_clk <= 0;
      pixel_read_buffer_pix_clk <= 0;
      dram_read_addr_pix_clk <= 0;
    end else if (dram_init_complete_pix_clk) begin

      if (dram_read_valid_pix_clk) begin
        pixel_read_buffer_pix_clk[current_inner_pixel_read_buffer_pix_clk] <= dram_read_data_pix_clk;
      end

      if ((vcount_pix_clk < `FRAME_HEIGHT) && (hcount_pix_clk < `FRAME_WIDTH)) begin
        pixel_read_buffer_addr_pix_clk <= pixel_read_buffer_addr_pix_clk + 1;

        if (pixel_read_buffer_addr_pix_clk == `PIXEL_BUFFER_SIZE - 1) begin
          current_inner_pixel_read_buffer_pix_clk <= ~current_inner_pixel_read_buffer_pix_clk;
        end

        if (pixel_read_buffer_addr_pix_clk == 'b0) begin
          if (dram_read_rdy_pix_clk) begin
            dram_read_addr_pix_clk <= pixel_addr_pix_clk + `PIXEL_BUFFER_SIZE;
            if (sw[0]) dram_read_rq_pix_clk <= 1;
          end else begin
            dram_read_rq_pix_clk <= 0;
          end
        end else begin
          dram_read_rq_pix_clk <= 0;
        end
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

  // vertices -> points
  logic [2:0][1:0][10:0] triangle_a;
  logic is_within_a;

  // x y z
  assign triangle_a[0] = {10'd100, 10'd100};
  assign triangle_a[1] = {10'd700, 10'd500};
  assign triangle_a[2] = {10'd900, 10'd800};

  triangle_2d_fill tfill_a (
      .rst(sys_rst),
      .clk(sys_clk),
      .hcount(hcount),
      .vcount(vcount),
      .triangle(triangle_a),
      .is_within(is_within_a)
  );

  always_comb begin
    if (sys_rst) begin
      current_pixel = 0;
    end else begin

      if (is_within_a) begin
        current_pixel = 16'hf0f;
      end else begin
        current_pixel = 16'b0;
      end

    end
  end

  always_ff @(posedge sys_clk) begin
    if (sys_rst) begin

      dram_write_rq <= 0;
      dram_write_addr <= 0;
      dram_write_data <= 0;

      pixel_write_buffer_addr <= 0;
      pixel_write_buffer <= 0;

      initial_dram_addr <= 0;

      hcount <= 0;
      vcount <= 0;

    end else if (dram_init_complete) begin
      if (dram_write_rdy || pixel_write_buffer_addr != `PIXEL_BUFFER_SIZE - 1) begin

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
        pixel_write_buffer[pixel_write_buffer_addr] <= current_pixel;

        if (pixel_write_buffer_addr == `PIXEL_BUFFER_SIZE - 1) begin
          dram_write_data <= {current_pixel, pixel_write_buffer[`PIXEL_BUFFER_SIZE-2:0]};
          dram_write_addr <= initial_dram_addr;

          if (sw[1]) dram_write_rq <= 1;

        end else begin
          dram_write_rq <= 0;
        end
      end else begin
        dram_write_rq <= 0;
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
