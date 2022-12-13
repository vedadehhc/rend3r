`default_nettype none
`timescale 1ns / 1ps

import proctypes::*;

// TODO: write eth into instruction_bank
module instruction_bank (
    input wire clk,
    input wire rst,
    input wire FetchAction action,
    input wire InstructionType dIType,
    output logic instruction_valid,
    output InstructionAddr pc_out,
    output Instruction inst
);

    typedef enum {fs_WAITING, fs_REPEAT_DEQUEUE} fetch_state;

    fetch_state state;
    logic valid_1;
    logic valid_2;

    logic canDequeue;
    // all 0 = end render/invalid UNLESS it is SD. 
    // So, we need feedback from decode if the previous inst was SE
    assign canDequeue = (action == fetchDequeue) && (instruction_out != {(INSTRUCTION_WIDTH){1'b0}} || dIType == opShapeSet);
    logic redirect_to_1;
    assign redirect_to_1 = (instruction_out == {21'b0, 2'b11, 6'b0, 3'b0}) && dIType != opShapeSet;

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
            state <= fs_WAITING;
        end  else if (action != fetchStall) begin
            if (redirect_to_1) begin
                pc <= 1;
                valid_1 <= 1'b0;
                valid_2 <= 1'b0;
            end else begin
                if (state == fs_WAITING) begin
                    valid_1 <= canDequeue;
                    if (canDequeue) begin
                        state <= fs_REPEAT_DEQUEUE;
                    end
                end else if (state == fs_REPEAT_DEQUEUE) begin
                    valid_1 <= 1'b1;
                    pc <= pc + 1;
                    state <= fs_WAITING;
                end
                valid_2 <= valid_1;
                pc_1 <= pc;
                pc_2 <= pc_1;
            end
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