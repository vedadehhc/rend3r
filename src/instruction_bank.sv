`default_nettype none
`timescale 1ns / 1ps

import proctypes::*;

module instruction_bank (
    input wire clk,
    input wire rst,
    input wire FetchAction action,
    output logic instruction_valid,
    output InstructionAddr pc_out,
    output Instruction inst
);
    logic valid_1;
    logic valid_2;

    InstructionAddr pc;
    InstructionAddr pc_1;
    InstructionAddr pc_2;

    always_ff @( posedge clk ) begin 
        if (rst) begin
            valid_1 <= 1'b0;
            valid_2 <= 1'b0;
            pc <= 0;
            pc_1 <= 0;
            pc_2 <= 0;
        end else begin
            valid_1 <= action == fetchDequeue;
            valid_2 <= valid_1;
            if (action == fetchDequeue) begin
                pc <= pc + 1;
            end
            pc_1 <= pc;
            pc_2 <= pc_1;
        end
    end

    logic [INSTRUCTION_WIDTH-1:0] instruction_out;

    xilinx_single_port_ram_read_first #(
        .RAM_WIDTH(INSTRUCTION_WIDTH),                       // Specify RAM data width
        .RAM_DEPTH(NUM_INSTRUCTIONS),                     // Specify RAM depth (number of entries)
        .RAM_PERFORMANCE("HIGH_PERFORMANCE"), // Select "HIGH_PERFORMANCE" or "LOW_LATENCY" 
        .INIT_FILE(`FPATH(main.mem))          // Specify name/location of RAM initialization file if using one (leave blank if not)
    ) inst_bank (
        .addra(pc),     // Address bus, width determined from RAM_DEPTH
        .dina(),       // RAM input data, width determined from RAM_WIDTH
        .clka(clk),       // Clock
        .wea(1'b0),         // Write enable
        .ena(1'b1),         // RAM Enable, for additional power savings, disable port when not in use
        .rsta(rst),       // Output reset (does not affect memory contents)
        .regcea(1'b1),   // Output register enable
        .douta(instruction_out)      // RAM output data, width determined from RAM_WIDTH
    );

    assign inst = instruction_out;
    assign instruction_valid = valid_2;
    assign pc_out = pc_2;
    
endmodule

`default_nettype wire