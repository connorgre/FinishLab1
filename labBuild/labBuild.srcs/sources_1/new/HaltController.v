`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/20/2022 03:14:59 PM
// Design Name: 
// Module Name: HaltController
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

// can't have 2 halt signals in a row and stop on both.  This is unexpected, and 
// this is the simplest solution.
module HaltController(haltOut, haltSig, haltReset, clk, reset);
    output reg  haltOut;
    input       haltSig, haltReset, clk, reset;

    reg canHalt;
    always@(negedge clk) begin
        if (haltReset) begin
            haltOut = 1'b0;
            canHalt = 1'b0;
        end else if (haltSig && canHalt) begin
            haltOut = 1'b1;
            canHalt = 1'b0;
        end else if (reset) begin
            haltOut = 1'b0;
            canHalt = 1'b1;
        end else begin
            haltOut = haltOut;
            canHalt = 1'b1;
        end
            
    end
    /*
    always@(posedge clk)
        if(haltState = 1'b0)
            haltOut <= 1'b0;
        else if(haltSig)
            haltOut <= 1'b1;
        else
            haltOut <= haltOut;
    */
endmodule
