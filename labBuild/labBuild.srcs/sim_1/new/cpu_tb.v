`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/18/2022 12:15:19 AM
// Design Name: 
// Module Name: cpu_tb
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
`include "opCodes.vh"
`define cycleClk #2.5 clk = ~clk; #2.5 clk = ~clk
`define halt op = `haltOp; arg1 = `r0; arg2 = `r0
module cpu_tb();

    wire [15:0] out;
    reg         clk, fullReset, resetPc, loadInstr, resetHalt;
    reg  [3:0]  op;
    reg  [5:0]  arg1, arg2;
    reg         runClock;

    wire [15:0] instr;
    wire haltOut;
    assign instr[15:12] = op;
    assign instr[11:6]  = arg1;
    assign instr[5:0]   = arg2;
    CPU cpuUUT (.out(out), 
                .clk(clk), 
                .resetPc(resetPc), 
                .loadInstr(loadInstr), 
                .instrIn(instr),
                .resetHalt(resetHalt), 
                .isHalted(haltOut));
    
    always@(posedge haltOut) begin
        #20 resetHalt = 1'b1;
        #4  resetHalt = 1'b0;
    end
    always begin
        if(runClock)
            #2.5 clk = ~clk;
        else
            #2.5;
    end
    

    initial begin
        runClock = 1'b0;
        `halt;
        loadInstr = 0;
        resetHalt   = 1'b0;
        clk         = 1'b0;
        `cycleClk;
        resetPc = 1'b1;
        `cycleClk;
        resetPc = 1'b0;
        resetHalt = 1'b1;
        `cycleClk;
        resetHalt = 1'b0;
        `cycleClk;
        runClock = 1'b1;
        // now the program should start running
        #500;
        $finish;
    end

endmodule
