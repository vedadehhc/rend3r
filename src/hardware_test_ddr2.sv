// `default_nettype none
// // test
// `timescale 1ns / 1ps
// /* 4:1 data rate + DDR => 16 * 8 = 128 */
// `define BURST_BITS 128 // = 16 bits a hword * 8 hwords a burst
// `define CACHE_BLOCK_BYTES 64 // 2 bytes a hword * 8 hwords a burst * 4 hwords in cache

// /* Hard coded */
// `define DRAM_ADDR_BITS 27



// module hwt_top_level (
//     input wire clk_100mhz,
//     input wire [15:0] sw,
//     input wire btnc,
//     input wire btnu,
//     input wire btnl,
//     input wire btnr,
//     input wire btnd,
//     output logic [7:0] an,
//     output logic caa,
//     cab,
//     cac,
//     cad,
//     cae,
//     caf,
//     cag,

//     output wire [15:0] led,

//     output logic [12:0] ddr2_addr,
//     output logic [2:0] ddr2_ba,
//     output logic ddr2_ras_n,
//     ddr2_cas_n,
//     output logic ddr2_we_n,
//     output logic ddr2_ck_p,
//     ddr2_ck_n,
//     ddr2_cke,
//     output logic ddr2_cs_n,
//     output logic [1:0] ddr2_dm,
//     output logic ddr2_odt,
//     inout wire [15:0] ddr2_dq,
//     inout wire [ 1:0] ddr2_dqs_n,
//     inout wire [ 1:0] ddr2_dqs_p,

//     output logic [3:0] vga_r,
//     vga_g,
//     vga_b,
//     output logic vga_hs,
//     vga_vs

// );

//   localparam CACHE_BLOCK_BITS = `CACHE_BLOCK_BYTES * 8;
//   localparam CACHE_BLOCK_BURSTS = CACHE_BLOCK_BITS / `BURST_BITS;

//   logic sys_rst, sys_clk, dram_ui_clk, clk_200mhz;

//   logic dram_read_data_fifo_write_valid, dram_write_data_fifo_write_valid;
//   logic dram_read_data_fifo_read_valid, dram_write_data_fifo_read_valid;

//   logic dram_write_data_fifo_empty, dram_write_data_fifo_full;
//   logic dram_read_data_fifo_empty, dram_read_data_fifo_full;

//   logic dram_read_rq, dram_read_rq_ui_clk, dram_write_rq, dram_write_rq_ui_clk;
//   logic dram_read_rdy_ui_clk, dram_write_rdy_ui_clk, dram_read_rdy, dram_write_rdy;

//   logic dram_read_valid;
//   logic [31:0] ssc_val;
//   logic [`DRAM_ADDR_BITS-1:0]
//       dram_read_addr, dram_read_addr_ui_clk, dram_write_addr, dram_write_addr_ui_clk;
//   logic [CACHE_BLOCK_BURSTS-1:0][`BURST_BITS-1:0]
//       dram_read_data,
//       dram_read_data_line,
//       dram_read_data_ui_clk,
//       dram_write_data,
//       dram_write_data_ui_clk;

//   assign sys_rst = sw[15];
//   assign dram_write_addr = dram_read_addr;
//   assign sys_clk = clk_200mhz;

//   clk_divider clk_div (
//       .clk_in_100(clk_100mhz),
//       .reset(sys_rst),
//       .clk_out_200(clk_200mhz)
//   );

//   cdc_pipe #(
//       .DATA_WIDTH(512)
//   ) read_data_cdc (
//       .rst(sys_rst),
//       .src_clk(dram_ui_clk),
//       .dest_clk(sys_clk),
//       .input_signal_src_clk(dram_read_data_ui_clk),
//       .output_signal_dest_clk(dram_read_data_line)
//   );

//   cdc_pipe #(
//       .DATA_WIDTH(512)
//   ) write_data_cdc (
//       .rst(sys_rst),
//       .src_clk(sys_clk),
//       .dest_clk(dram_ui_clk),
//       .input_signal_src_clk(dram_write_data),
//       .output_signal_dest_clk(dram_write_data_ui_clk)
//   );

//   cdc_pipe read_rdy_cdc (
//       .rst(sys_rst),
//       .src_clk(dram_ui_clk),
//       .dest_clk(sys_clk),
//       .input_signal_src_clk(dram_read_rdy_ui_clk),
//       .output_signal_dest_clk(dram_read_rdy)
//   );

//   cdc_pipe write_rdy_cdc (
//       .rst(sys_rst),
//       .src_clk(dram_ui_clk),
//       .dest_clk(sys_clk),
//       .input_signal_src_clk(dram_write_rdy_ui_clk),
//       .output_signal_dest_clk(dram_write_rdy)
//   );

//   cdc_pipe read_valid_cdc (
//       .rst(sys_rst),
//       .src_clk(dram_ui_clk),
//       .dest_clk(sys_clk),
//       .input_signal_src_clk(dram_read_valid_ui_clk),
//       .output_signal_dest_clk(dram_read_valid)
//   );

//   cdc_pulse read_rq_cdc (
//       .rst(sys_rst),
//       .src_clk(sys_clk),
//       .dest_clk(dram_ui_clk),
//       .input_signal_src_clk(dram_read_rq),
//       .output_signal_dest_clk(dram_read_rq_ui_clk)
//   );

//   cdc_pulse write_rq_cdc (
//       .rst(sys_rst),
//       .src_clk(sys_clk),
//       .dest_clk(dram_ui_clk),
//       .input_signal_src_clk(dram_write_rq),
//       .output_signal_dest_clk(dram_write_rq_ui_clk)
//   );

//   cdc_pipe read_addr_cdc (
//       .rst(sys_rst),
//       .src_clk(sys_clk),
//       .dest_clk(dram_ui_clk),
//       .input_signal_src_clk(dram_read_addr),
//       .output_signal_dest_clk(dram_read_addr_ui_clk)
//   );

//   cdc_pipe write_addr_cdc (
//       .rst(sys_rst),
//       .src_clk(sys_clk),
//       .dest_clk(dram_ui_clk),
//       .input_signal_src_clk(dram_write_addr),
//       .output_signal_dest_clk(dram_write_addr_ui_clk)
//   );

//   logic dram_read_valid_ui_clk;

//   // 4 bursts in cache * (8 words a burst * 16 bits a hword) = 512 bits
//   dram #(
//       .BURST_BITS(`BURST_BITS),
//       .CACHE_BLOCK_BYTES(`CACHE_BLOCK_BYTES),
//       .DRAM_ADDR_BITS(`DRAM_ADDR_BITS)
//   ) my_dram (
//       .pclk(sys_clk),
//       .rst(sys_rst),
//       .sclk(dram_ui_clk),
//       .read_ready(dram_read_rdy_ui_clk),
//       .read_request(dram_read_rq_ui_clk),
//       .read_address(dram_read_addr_ui_clk),
//       .read_response(dram_read_valid_ui_clk),
//       .read_data(dram_read_data_ui_clk),
//       .write_ready(dram_write_rdy_ui_clk),
//       .write_request(dram_write_rq_ui_clk),
//       .write_address(dram_write_addr_ui_clk),
//       .write_data(dram_write_data_ui_clk),

//       /* DDR output signals strung straight to the top level */
//       .ddr2_addr(ddr2_addr),
//       .ddr2_ba(ddr2_ba),
//       .ddr2_ras_n(ddr2_ras_n),
//       .ddr2_cas_n(ddr2_cas_n),
//       .ddr2_we_n(ddr2_we_n),
//       .ddr2_ck_p(ddr2_ck_p),
//       .ddr2_ck_n(ddr2_ck_n),
//       .ddr2_cke(ddr2_cke),
//       .ddr2_cs_n(ddr2_cs_n),
//       .ddr2_dm(ddr2_dm),
//       .ddr2_odt(ddr2_odt),
//       .ddr2_dq(ddr2_dq),
//       .ddr2_dqs_p(ddr2_dqs_p),
//       .ddr2_dqs_n(ddr2_dqs_n)
//   );

//   seven_segment_controller my_ssc (
//       .clk_in (sys_clk),
//       .rst_in (sys_rst),
//       .val_in (ssc_val),
//       .cat_out({cag, caf, cae, cad, cac, cab, caa}),
//       .an_out (an)
//   );

//   button bu (
//       .clk(sys_clk),
//       .rst(sys_rst),
//       .raw_in(btnu),
//       .pulse_out(p_btnu),
//       .clean_out(c_btnu)
//   );
//   button bd (
//       .clk(sys_clk),
//       .rst(sys_rst),
//       .raw_in(btnd),
//       .pulse_out(p_btnd),
//       .clean_out(c_btnd)
//   );
//   button bl (
//       .clk(sys_clk),
//       .rst(sys_rst),
//       .raw_in(btnl),
//       .pulse_out(p_btnl),
//       .clean_out(c_btnl)
//   );
//   button br (
//       .clk(sys_clk),
//       .rst(sys_rst),
//       .raw_in(btnr),
//       .pulse_out(p_btnr),
//       .clean_out(c_btnr)
//   );
//   button bc (
//       .clk(sys_clk),
//       .rst(sys_rst),
//       .raw_in(btnc),
//       .pulse_out(p_btnc),
//       .clean_out(c_btnc)
//   );

//   logic p_btnu, p_btnd, p_btnl, p_btnr, p_btnc, reading;
//   logic c_btnu, c_btnd, c_btnl, c_btnr, c_btnc;

//   // am i reading or writing?
//   assign reading  = ~sw[0];
//   assign led[0]   = sw[0];

//   assign led[15]  = dram_read_rdy;
//   assign led[14]  = dram_write_rdy;

//   assign led[13]  = dram_read_rq;
//   assign led[12]  = dram_write_rq;

//   assign led[11]  = dram_read_valid;
//   //what the address im writing to? control with left, right
//   assign led[10]  = dram_ui_clk;
//   assign led[9:1] = dram_read_addr;

//   assign ssc_val  = reading ? dram_read_data : dram_write_data[0][31:0];

//   always_ff @(posedge sys_clk) begin
//     if (sys_rst) begin

//       dram_read_addr <= 0;
//       dram_read_data <= 0;
//       dram_write_data <= 0;

//       dram_read_rq <= 0;
//       dram_write_rq <= 0;

//     end else begin

//       if (p_btnr) begin
//         dram_read_addr <= dram_read_addr + 1;
//       end else if (p_btnl) begin
//         dram_read_addr <= dram_read_addr - 1;
//       end

//       if (p_btnu) begin
//         dram_write_data[0][31:0] <= dram_write_data[0][31:0] + 1;
//       end else if (p_btnd) begin
//         dram_write_data[0][31:0] <= dram_write_data[0][31:0] - 1;
//       end

//       if (p_btnc) begin
//         if (reading) begin
//           dram_read_rq <= 1;
//         end else begin
//           dram_write_rq <= 1;
//         end
//       end

//       if (dram_write_rq) begin
//         dram_write_rq <= 0;
//       end

//       if (dram_read_rq) begin
//         dram_read_rq <= 0;
//       end

//       if (dram_read_valid) begin
//         dram_read_data <= dram_read_data_line;
//       end

//     end
//   end

// endmodule
// `default_nettype wire
