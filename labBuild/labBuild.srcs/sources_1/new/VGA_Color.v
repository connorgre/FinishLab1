`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/21/2022 06:47:05 PM
// Design Name: 
// Module Name: VGA_Color
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


module VGA_Color(color1Out, color2Out, color3Out, rfStreamIn, loadInstr, loadClk, resetPc, x, y, clk, cpuClk);
    output reg  [3:0]   color1Out;
    output reg  [3:0]   color2Out;
    output reg  [3:0]   color3Out;
    input       [127:0] rfStreamIn;
    input       [10:0]    x, y;
    input               clk, loadInstr, loadClk, resetPc, cpuClk;
    
    integer maxX = 800; // total number of visible columns
    integer maxY = 525; // total number of visible lines
    integer columnWidth = 30;
    integer rowHeight  =  30;

    parameter regBits = 16;
    parameter sqSize = 10;
    
    integer i;
    integer j;
    reg colorBit;
    reg colorBorder;
        
    always@(posedge clk) begin
        colorBit = 1'b0;
        colorBorder = 1'b0;
        if (y < 400) begin
            for (i = 0; i < 8; i=i+1) begin
                for (j = 0; j < 16; j= j+1) begin
                    if ((x > (columnWidth * j + 40)) && (x < ((columnWidth * j + 40) + sqSize)))
                        if (( y > (rowHeight * i + 30)) && (y < ((rowHeight * i + 30) + sqSize)))
                            colorBit = rfStreamIn[i*16 + j];
                    if ((x > (columnWidth * j + 35)) && (x < ((columnWidth * j + 45) + sqSize)))
                        if (( y > (rowHeight * i + 25)) && (y < ((rowHeight * i + 45) + sqSize)))
                            colorBorder = 1'b1;
                end
            end
        end else begin
            if ( y > 410 && y < 440) begin
                if (x > 110 && x < 140) begin
                    if (cpuClk)
                        colorBit = 1'b1;
                    else
                        colorBit = 1'b0;
                end else if (x > 210 && x < 240) begin
                    if (loadInstr)
                        colorBit = 1'b1;
                    else
                        colorBit = 1'b0;
                end else if ( x > 310 && x < 340) begin 
                    if (loadClk)
                        colorBit = 1'b1;
                    else
                        colorBit = 1'b0;       
                end else if (x > 410 && x < 440)begin
                    if (resetPc)
                        colorBit = 1'b1;
                    else
                        colorBit = 1'b0;
                end
            end
            if ( y > 400 && y < 450) begin
                if (x > 100 && x < 150)
                    colorBorder = 1'b1;
                if (x > 200 && x < 250)
                    colorBorder = 1'b1;
                else if ( x > 300 && x < 350)
                    colorBorder = 1'b1;        
                else if (x > 400 && x < 450)
                    colorBorder = 1'b1;
            end
        end
        if(colorBit)
            color1Out = 4'hF;
        else
            color1Out = 4'h4;
        if(colorBorder)
            color2Out = 4'hF;
        else
            color2Out = 4'h4;
        color3Out = 4'hF;
    end
endmodule
