`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/21/2022 05:35:22 PM
// Design Name: 
// Module Name: Btn_ctrl
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


module Btn_ctrl(clk, BTND, BTNU, BTNC, BTNL, BTNR, isHalted,
                unHalt, resetPc, loadInstr, advanceLoad
                );
    input      clk, BTND, BTNU, BTNC, BTNL, BTNR, isHalted;
    output reg unHalt, resetPc, loadInstr, advanceLoad;
    wire uHltBtn = BTNU;
    wire rPcBtn = BTND;
    wire deBounce = BTNC;
    wire loadInstrBtn = BTNL;
    wire advLoadBtn = BTNR;
    
    
    reg canSignalUnHalt;
    reg canSignalResetPc;
    reg canCycleAdvanceLoad;
    reg canSwitchLoad;
    
    always@(posedge clk) begin
        if (deBounce) begin
            unHalt    = 1'b0;
            resetPc   = 1'b0;
            advanceLoad = 1'b0;
            canSignalUnHalt = 1'b1;
            canSignalResetPc = 1'b1;
            canCycleAdvanceLoad = 1'b1;
            canSwitchLoad = 1'b1;
        end
        else begin 
            if (uHltBtn && canSignalUnHalt) begin
                unHalt = 1'b1;
                canSignalUnHalt = 1'b0;
            end else if(isHalted == 1'b0)
                unHalt = 1'b0;
                
            if (rPcBtn && canSignalResetPc) begin
                resetPc = 1'b1;
                canSignalResetPc = 1'b0;
            end
            
            if(advLoadBtn && canCycleAdvanceLoad) begin
                advanceLoad = 1'b1;
                canCycleAdvanceLoad = 1'b0;
            end
            
            if(loadInstrBtn && canSwitchLoad) begin
                if (resetPc)
                    loadInstr = 1'b1;
                else
                    loadInstr = 1'b0;
                canSwitchLoad = 1'b0;
            end
            
        end
    end
    
    
endmodule
