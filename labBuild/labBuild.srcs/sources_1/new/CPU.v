`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/09/2022 10:15:44 PM
// Design Name: 
// Module Name: CPU
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

// 5 stage pipelined cpu
//      all wires specific to 1 stage should be
//      suffixed with the below notation
//      at the end of each stage, all outputs from
//      the stage should enter a register, and
//      come out the other end with the next
//      stage suffix
// _if = instruction fetch
// _id = instruction decode
// _ex = execute (alu stage)
// _me = memory
// _wb = writeback
//
// These ~could~ each be put into their own module, however I don't think that is totally
// necessary, as each stage should really just be passing stuff into submodules and 
// passing into registers. Part of the reason this would be difficult is multiple 
// stages need to access memory (Fetch and Memory), and multiple need the register file
// (Decode and WriteBack).  Additionally, it would make finding hazards more difficult
module CPU(out, clk, resetPc, resetHalt, rfStreamOut, loadInstr, instrIn, isHalted);
    parameter regBits = 3;
    input clk, resetPc, resetHalt, loadInstr;
    input [15:0]           instrIn;
    output [16 * 8 - 1:0]  rfStreamOut; // large bus holding all the register data
    output [15:0] out;
    output isHalted;
// forward declarations         <- should eventually move all the register wires here
    wire [2:0]  readReg1_ME;
    wire [2:0]  readReg2_ME;
    wire [2:0]  writeReg_ME;
    wire        writeMem_ME;
    wire [15:0] memAddress_ME;
    wire [15:0] memDataOut_ME;
    wire [15:0] memDataIn_ME;
    wire [2:0]  writeReg_WB;
    wire        regWrite_WB;
    wire        regWrite_ME;
    wire [15:0] aluOut_ME;
    wire [15:0] outData_WB;
    wire        readMem_EX;
    wire        movMem_ME;
                  
    wire        doJump_ID;
    wire [11:0] jumpTarget;
    wire        cmpRes_EX;
    wire        globalHalt;
    assign isHalted = globalHalt;
    // want to make sure we can write the 0s, and that we aren't halting
    // the registers during the load phase
    wire        globalRegEn = (~globalHalt | resetPc) & (~loadInstr);
    wire [6:0] ctrlBus_ME;          
    wire [6:0] ctrlBus_WB;
    wire [15:0] regData2_ME;
    
    reg prevJump;


///////////////////////////////////////////////////////////////////////
////////////////        -- INSTRUCTION FETCH --        ////////////////
///////////////////////////////////////////////////////////////////////
    wire [15:0] pc_IF;      // comes from register file
    wire [15:0] firstPc;
    wire [15:0] nextPc;
    wire [15:0] instr_IF;
    wire   regWrite;
    // The simulator requires that the code be loaded into location 31 (decimal).
    // this muxes the pc_if (from nextPc -> reg -> pc_if), with this initial value
    assign firstPc = 16'd31;
    reg resetPcReg;
    always@(posedge clk) begin
        if (resetPc == 1'b1)
            resetPcReg = 1'b1;
        else
            resetPcReg = 1'b0;
    end
    wire [15:0] currPc = (resetPcReg == 1'b1) ? firstPc : pc_IF;
    //wire [15:0] memPcIn = (doJump_ID == 1'b1 && (loadInstr == 1'b0)) ? {4'b0000, jumpTarget} : currPc;
    IncrementPC pcInc (.pcIn(currPc), .pcOut(nextPc), .clk(clk), .enable(globalRegEn));
    
    // pcIn is the current program counter
    // instrOut is the instruction read from memory        // writeMem_ME, movMem_ME == 1'b0 until reset, so give guaranteed signal
    wire writeToMem       = (resetPc == 1'b1) ? 1'b0   : ((loadInstr == 1'b1) ? 1'b1 : writeMem_ME);
    wire movMem           = (resetPc == 1'b1) ? 1'b0   : movMem_ME;
    wire [15:0] memAddrIn = (loadInstr == 1'b1) ? currPc : memAddress_ME;    // <- write to mem when loading instructions
    wire [15:0] memDataIn = (loadInstr == 1'b1) ? instrIn : memDataIn_ME;
    
    Memory mem (.clk(clk),
                .write(writeToMem),
                .movMem(movMem),
                .address(memAddrIn),
                .dataIn(memDataIn),
                .dataOut(memDataOut_ME),
                .pcIn(currPc),
                .instrOut(instr_IF));
                
    // this is an inut into the register file
    wire [15:0] nextPcToReg = (resetPc == 1'b1) ? firstPc : ((doJump_ID == 1'b1 && (loadInstr == 1'b0)) ? {4'b0000, jumpTarget} : nextPc);
    
    wire haltOut;
    // want don't want to halt after we reset the program counter
    wire haltReset = (doJump_ID == 1'b1) ? 1'b0 : resetHalt;
    HaltController  haltCtrl  ( .haltOut(haltOut),
                                .haltSig(halt_ID),
                                .haltReset(haltReset),
                                .clk(clk),
                                .reset(resetPc));
    // passes current instruction into decode
    wire [15:0] instr_ID;
    
    /*
    NBitReg #(.N(16)) regInstr_ID_EX (.inData(instr_IF), 
                                          .outData(instr_ID),
                                          .enable(globalRegEn | loadInstr),
                                          .clk(clk),
                                          .reset(resetPc));
    */
    assign instr_ID = instr_IF;

////////////////////////////////////////////////////////////////////////////////////
////////////////              -- INSTRUCTION DECODE --             /////////////////
////////////////////////////////////////////////////////////////////////////////////
// decodes instruction, sets cmpReg (NEED TO DO), gets register data.
// INPUT:   instr_ID
// OUTPUT:  regData1_EX, 
//          regData2_EX, 
//          readReg1_EX, 
//          readReg2_EX, 
//          ctrlBus_EX,  
//          aluOp_EX,
//          writeReg_EX
    wire [3:0] opCode;
    wire [5:0] arg1;
    wire [5:0] arg2;

    InstrDecode decoder(.instr(instr_ID),
                        .opCode(opCode),
                        .arg1(arg1),
                        .arg2(arg2));
    
    wire [15:0]         regData1_ID,
                        regData2_ID;

    wire [regBits-1:0]  writeReg_ID,
                        readReg1_ID,
                        readReg2_ID,
                        writeReg_EX,
                        readReg1_EX,
                        readReg2_EX;
                        
    assign readReg1_ID = arg1[2:0];
    assign writeReg_ID = arg1[2:0];
    assign readReg2_ID = arg2[2:0];
    wire writeToRegFile = (resetPc == 1'b1) ? 1'b0 : ((loadInstr) ? 1'b1 : regWrite_WB);
    wire [2:0] writeReg = (loadInstr) ? 3'd6 : writeReg_WB;
    wire pcEnable = globalRegEn | loadInstr;
    RegisterFile regFile (.clk(clk),
                          .reset(resetPc),
                          .writeData(outData_WB),
                          .writeReg(writeReg_WB),
                          .regWrite(writeToRegFile),
                          .readReg1(readReg1_ID),
                          .readReg2(readReg2_ID),
                          .readData1(regData1_ID),
                          .readData2(regData2_ID),
                          .pcIn(nextPcToReg),
                          .pcOut(pc_IF),
                          .pcEnable(pcEnable),
                          .rfStreamOut(rfStreamOut));
    
    // see comment in module if je and jne have hazards with a cmp instruction
    // right before them.  This ~shouldn't~ be an issue but could be.
    JumpController jumpCtrl (   .opCode(opCode),
                                .cmpResult(cmpRes_EX),
                                .reset(resetPc),
                                .doJump(doJump_ID));
    always@(posedge clk)
        prevJump = doJump_ID;
    assign jumpTarget[11:0] = {arg1, arg2} - 1;
    
    wire        regWrite_ID;
    wire        readMem_ID;
    wire        writeMem_ID;
    wire        aluImm_ID;
    wire        movMem_ID;            // <- unused. don't feel like fixing yet.
    wire        halt_ID;
    wire        cmpWrite_ID;
    wire [2:0]  aluOp_ID;
    wire        forceCtrlZero = resetPc;
    control control_i ( .opCode(opCode),
                        .forceZero(forceCtrlZero),
                        .regWrite(regWrite_ID),
                        .readMem(readMem_ID),
                        .writeMem(writeMem_ID),
                        .aluImm(aluImm_ID),
                        .movMem(movMem_ID),
                        .halt(halt_ID),
                        .cmpWrite(cmpWrite_ID),             
                        .aluOp(aluOp_ID));
    
    
    assign globalHalt = haltOut & ~prevJump;

    wire [6:0] ctrlBus_ID;
    wire [6:0] ctrlBus_EX;
    assign ctrlBus_ID[6:0] = {movMem_ID, regWrite_ID, readMem_ID, writeMem_ID, 
                           aluImm_ID, cmpWrite_ID, halt_ID};

    wire [15:0] regData1_EX;
    wire [15:0] regData2_EX;
    
    wire [2:0]  aluOp_EX;
    wire [5:0] imm_EX;

    assign regData1_EX = regData1_ID;
    assign regData2_EX = regData2_ID;
    assign writeReg_EX = writeReg_ID;
    assign ctrlBus_EX = ctrlBus_ID;
    assign aluOp_EX = aluOp_ID;
    assign imm_EX = arg2;
////////////////////////////////////////////////////////////////////////////////////
////////////////                   -- EXECUTION --                 /////////////////
////////////////////////////////////////////////////////////////////////////////////

    assign regWrite   = ctrlBus_EX[5];
    assign readMem_EX = ctrlBus_EX[4];
    wire aluImm_EX    = ctrlBus_EX[2];
    wire cmpWrite_EX  = ctrlBus_EX[1];
    wire halt_EX      = ctrlBus_EX[0];
    wire [15:0]         aluIn1,
                        aluIn2;

    assign aluIn1 = regData1_EX;
    ALU_Mux aluMuxIn2 ( .regData2(regData2_EX), 
                        .arg2(imm_EX), 
                        .ALUSrc(~aluImm_EX), 
                        .ALU_Mux_out(aluIn2));

    wire [15:0]   aluOut_EX;
    wire          aluCmpRes;
    ALU alu (   .aluIn1(aluIn1), 
                .aluIn2(aluIn2), 
                .aluOp(aluOp_EX), 
                .ALUresult(aluOut_EX),
                .cmpRes(aluCmpRes));
    
    CompareHandle cmpCtrl ( .cmpInstr(cmpWrite_EX), 
                            .aluEqRes(aluCmpRes),
                            .reset(resetPc), 
                            .cmpResult(cmpRes_EX), 
                            .clk(clk));
    
    
    assign aluOut_ME = aluOut_EX;
    assign regData2_ME = regData2_EX;
    assign ctrlBus_ME = ctrlBus_EX;
    
    assign readReg2_ME = readReg2_EX;
    assign writeReg_ME = writeReg_EX;
    
////////////////////////////////////////////////////////////////////////////////////
////////////////                    -- MEMORY --                   /////////////////
////////////////////////////////////////////////////////////////////////////////////
// handles memory
/*
   INPUT:   aluOut_ME,
            regData2_ME,
            ctrlBus_ME,
            readReg1_ME,
            readReg2_ME,
            writeReg_ME
    OUTPUT: outData_WB,
            ctrlBus_WB,
            writeReg_WB
*/
    assign movMem_ME   = ctrlBus_ME[6];
    assign regWrite_ME = ctrlBus_ME[5];
    wire readMem_ME    = ctrlBus_ME[4];
    assign writeMem_ME = ctrlBus_ME[3];
    
    // THE MEMORY UNIT IS INSTANTIATED IN INSTRUCTION FETCH STAGE
    // memAddress_ME, memDataIn_ME, writeMem_ME, and readMem_ME are
    // all instantiated in Instruction Fetch
    MemoryInterface memCtrl (   .regData1(aluOut_ME),
                                .regData2(regData2_ME),
                                .memWrite(writeMem_ME),
                                .memAddress(memAddress_ME),
                                .memData(memDataIn_ME));
    wire [15:0] memAluMuxOut;
    Mux2to1 memOutMux ( .out(memAluMuxOut),
                        .in1(memDataOut_ME),
                        .in2(aluOut_ME),
                        .select(readMem_ME));
   
    assign outData_WB = memAluMuxOut;
    assign ctrlBus_WB = ctrlBus_ME;
    assign writeReg_WB = writeReg_ME;
                                    
////////////////////////////////////////////////////////////////////////////////////
////////////////                  -- WRITE BACK --                 /////////////////
////////////////////////////////////////////////////////////////////////////////////
// writes data back to register file.  This is it's own stage to help avoid
// RAW and WAR hazards. While likely the clock will be slow enough that this isn't
// a problem, add it for completeness
/*
    INPUT:  outData_WB,
            ctrlBus_WB,
            writeReg_WB
    OUTPUT: NONE -- but writes to register file
*/
    // this is declared in ID stage, bc register file is instantiated there
    assign regWrite_WB = regWrite;
    assign out = (regWrite_WB) ? outData_WB : ((globalHalt) ? 16'd11111 : 16'd33333);
endmodule
