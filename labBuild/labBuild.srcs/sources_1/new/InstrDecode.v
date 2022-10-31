`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/09/2022 08:09:28 PM
// Design Name: 
// Module Name: InstrDecode
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

// need to implement immediates and jump targets
module InstrDecode(
    input [15:0] instr,
    output reg [3:0] opCode,
    output reg [5:0] arg1,
    output reg [5:0] arg2
    );
    always@(instr) begin
        opCode = instr[15:12];
        if (instr[15:12] == `incOp) begin
            arg2   = instr[11:6];
            arg1   = instr[5:0];
        end else begin
            arg1   = instr[11:6];
            arg2   = instr[5:0];
        end
    end
endmodule
