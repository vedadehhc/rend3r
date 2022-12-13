// `define BURST_BITS 128 // = 16 bits a hword * 8 hwords a burst
// `define CACHE_BLOCK_BYTES 64 // 2 bytes a hword * 8 hwords a burst * 4 hwords in cache
// `define CACHE_BLOCK_BITS `CACHE_BLOCK_BYTES * 8
// `define CACHE_BLOCK_BURSTS `CACHE_BLOCK_BITS / `BURST_BITS
// `define BURST_CTR_BITS $clog2(`CACHE_BLOCK_BURSTS)
// `define PIXEL_BUFFER_SIZE 8
// `define PIXEL_BUFFER_ADDR_BITS $clog2(`PIXEL_BUFFER_SIZE)
// `define DRAM_ADDR_BITS 27
// `define FRAME_WIDTH 1024
// `define FRAME_HEIGHT 768
// `define COLOR_WIDTH 12
// `define FRAME_WIDTH_BITS 11
// `define FRAME_HEIGHT_BITS 11
// `define MAX_HCOUNT 1344

// `timescale 1ns / 1ps

// module pix_write (
//     input wire sys_clk,
//     input wire sys_rst
// );

//   logic dram_write_rq;
//   logic [`DRAM_ADDR_BITS-1:0] dram_write_addr, initial_dram_addr;

//   logic [15:0] current_pixel;
//   logic [127:0] dram_write_data;
//   logic [`FRAME_WIDTH_BITS-1:0] hcount;  // pixel on current line
//   logic [`FRAME_HEIGHT_BITS-1:0] vcount;
//   logic [`PIXEL_BUFFER_ADDR_BITS-1:0] pixel_write_buffer_addr;
//   logic [`PIXEL_BUFFER_SIZE-1:0][15:0] pixel_write_buffer;

//   logic pixel_addr;
//   assign pixel_addr = `FRAME_WIDTH * vcount + hcount;

//   always_comb begin
//     if (sys_rst) begin
//       current_pixel = 0;
//     end else begin
//       if ((vcount > 600) && (vcount < 700)) begin
//         current_pixel = 16'h0f0f;
//       end else if ((hcount > 400) && (hcount < 500) && (vcount > 400) && (vcount < 500)) begin
//         current_pixel = 16'h000f;
//       end else begin
//         current_pixel = 16'h0ff0;
//       end
//     end
//   end


//   always_ff @(posedge sys_clk) begin
//     if (sys_rst) begin
//       dram_write_rq <= 0;

//       dram_write_addr <= 0;

//       pixel_write_buffer_addr <= 0;
//       pixel_write_buffer <= 0;

//       initial_dram_addr <= 0;

//       hcount <= 380;
//       vcount <= 380;

//     end else begin
//       if (hcount == `FRAME_WIDTH - 1) begin
//         hcount <= 0;
//         if (vcount == `FRAME_HEIGHT - 1) begin
//           vcount <= 0;
//         end else begin
//           vcount <= vcount + 1;
//         end
//       end else begin
//         hcount <= hcount + 1;
//       end

//       if (pixel_write_buffer_addr == 'b0) begin
//         initial_dram_addr <= pixel_addr;
//       end

//       pixel_write_buffer_addr <= pixel_write_buffer_addr + 1;
//       pixel_write_buffer[pixel_write_buffer_addr] <= current_pixel;

//       if (pixel_write_buffer_addr == `PIXEL_BUFFER_SIZE - 1) begin
//         dram_write_data <= {current_pixel, pixel_write_buffer[`PIXEL_BUFFER_SIZE-2:0]};
//         dram_write_addr <= initial_dram_addr;

//         dram_write_rq   <= 1;

//       end else begin
//         dram_write_rq <= 0;
//       end

//     end

//   end
// endmodule
