`default_nettype none
`timescale 1ns / 1ps

import proctypes::*;

// 1 stage pipeline - register on output
module parser (
    input wire clk,
    input wire rst,
    input wire [31:0] instruction,
    input wire valid_in,
    output logic valid_out,
    output DecodedInst dInst,
    output logic [NUM_INSTRUCTIONS-1:0] pc
);
    logic nextShapeData;

    DecodedInst nextDInst = DecodedInst'(0);
    OpCode opcode = OpCode'(0);
    logic [1:0] func;

    always @(*) begin
        if (nextShapeData) begin
            nextDInst.iType = opShapeData;
            nextDInst.data  = instruction[31:16];
            nextDInst.data2 = instruction[15:0];
        end else begin
            opcode = OpCode'(instruction[2:0]);

            case (opcode)
                ocFType: begin
                    func = instruction[10:9];
                    if (func == 2'b00) begin
                        nextDInst.iType = opRender;
                    end else begin
                        nextDInst.iType = opFrame;
                    end
                end
                ocCType: begin
                    nextDInst.iType = opCameraSet;
                    nextDInst.prop = instruction[15:11];
                    nextDInst.data = instruction[31:16];
                end
                ocLType: begin
                    nextDInst.iType = opLightSet;
                    nextDInst.lIndex = instruction[8:3];
                    nextDInst.prop = instruction[15:11];
                    nextDInst.data = instruction[31:16];
                end
                ocSIType: begin
                    nextDInst.iType = opShapeInit;
                    nextDInst.sIndex = {instruction[31:16], instruction[5:3]};
                    nextDInst.sType = ShapeType'(instruction[15:11]);
                end
                ocSEType: begin
                    nextDInst.iType = opShapeSet;
                    nextDInst.sIndex = {instruction[31:16], instruction[5:3]};
                    nextDInst.prop = instruction[15:11];
                    nextDInst.prop2 = instruction[10:6];
                end
                default: begin
                    nextDInst.iType = opUnsupported;
                end
            endcase
        end 
    end

    always_ff @( posedge clk ) begin 
        if (rst) begin
            nextShapeData <= 1'b0;
            valid_out <= 1'b0;
            dInst <= 0;
            pc <= 0;
        end else begin
            if (valid_in) begin
                pc <= pc + 1;
            end
            valid_out <= valid_in;
            dInst <= nextDInst;
            if (valid_in && (nextDInst.iType == opShapeSet)) begin
                nextShapeData <= 1'b1;
            end else if (valid_in) begin
                nextShapeData <= 1'b0;
            end
        end
    end
endmodule

`default_nettype wire
