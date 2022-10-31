`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/09/2022 07:32:30 PM
// Design Name: 
// Module Name: RegisterFile
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

// R6 is the program counter, and is NOT stored in the register file, it is
// much simpler implementation-wise to have the PC be its own independent register
module RegisterFile(clk, reset, writeData, writeReg, regWrite, readReg1, readReg2, 
                    readData1, readData2, pcIn, pcOut, pcEnable, rfStreamOut);
    parameter bitLen = 16; // bitlength of registers
    parameter regBits = 3; // number registers is 2**regBits
   
    output [bitLen-1:0] readData1, readData2;
    output reg [bitLen-1:0] pcOut;
    reg    [bitLen-1:0] readData1, readData2;
    output [16 * 8 - 1:0]  rfStreamOut;
    input               reset, pcEnable;
    input [bitLen-1:0]  writeData, pcIn;
    input [regBits-1:0] writeReg, readReg1, readReg2;
    input               regWrite, clk;
   
    integer       i;
    reg [bitLen-1:0]    Reg_File[(2**regBits)-1:0]; //2**regBits registers of bitLen length
   
    always @(readReg1, readReg2, writeReg, regWrite) // <- always want to be reading from the register file
    begin
        readData1 <= Reg_File[readReg1];
        readData2 <= Reg_File[readReg2];
    end
        
    always @(posedge clk)
    begin
        if (reset) begin
             for (i=0; i<(2**regBits); i=i+1)
                if (i != 6)
                    Reg_File[i] <= 0;
                else
                    Reg_File[6] <= 6'd31;
            pcOut <= 6'd31;
        end else begin
            if (regWrite) begin
                Reg_File[writeReg] <= writeData;
            end
            if (pcEnable) begin
                Reg_File[6] <= pcIn;
                pcOut <= pcIn;
            end else
                pcOut <= Reg_File[6];
        end
    end
    
    // streamout to VGA
    genvar iG;
    generate
        for (iG = 0; iG < 8; iG=iG+1) begin
            assign rfStreamOut[16*(iG+1)-1:(16)*iG] = Reg_File[iG];
        end
    endgenerate
    
endmodule
