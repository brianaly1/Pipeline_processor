// ---------------------------------------------------------------------
// Copyright (c) 2007 by University of Toronto ECE 243 development team 
// ---------------------------------------------------------------------
//
// Major Functions:	a simple processor which operates basic mathematical
//					operations as follow:
//					(1)loading, (2)storing, (3)adding, (4)subtracting,
//					(5)shifting, (6)oring, (7)branch if zero,
//					(8)branch if not zero, (9)branch if positive zero
//					 
// Input(s):		1. KEY0(reset): clear all values from registers,
//									reset flags condition, and reset
//									control FSM
//					2. KEY1(clock): manual clock controls FSM and all
//									synchronous components at every
//									positive clock edge
//
//
// Output(s):		1. HEX Display: display registers value K3 to K1
//									in hexadecimal format
//
//					** For more details, please refer to the document
//					   provided with this implementation
//
// ---------------------------------------------------------------------

module multicycle
(
SW, KEY, HEX0, HEX1, HEX2, HEX3,
HEX4, HEX5, LEDR
);

// ------------------------ PORT declaration ------------------------ //
input	[1:0] KEY;
input [4:0] SW;
output	[6:0] HEX0, HEX1, HEX2, HEX3;
output	[6:0] HEX4, HEX5;
output reg [17:0] LEDR;

// ------------------------- Registers/Wires ------------------------ //
wire	clock, reset;
wire	PCWrite, MemRead, MemWrite, S1Load, S2Load, R1Sel, RegWsel, RFWrite, R1B, R2B, Countwrite; 
wire	S3Load, ALU1, FlagWrite, ALU3, WBIRLoad, NOOPSel1, NOOPSel2, NOOPSel3, NOOPSel4;   
wire	[15:0] CountOut,NextCountwire, NextPCwire, CountAdder1wire, CountAdder2wire, PCAdder1wire, PCAdder2wire, NOOPMuxWire1, NOOPMuxWire2, NOOPMuxWire3, NOOPMuxWire4 ;
wire	[7:0] R2wire, PCwire, PC1wire, PC2wire, PC3wire, R1wire, RFout1wire, RFout2wire, Data1Wire, Data2Wire, PC4wire;
wire	[7:0] ALU1wire, ALU2wire, ALU3wire, ALUwire, ALUOut, MEMwire, IRMEMwire;
wire	[7:0] DIR, RFIR, XIR, WBIR, SE4wire, ZE5wire, ZE3wire, AddrWire,AddrWire2;
wire	[7:0] reg0, reg1, reg2, reg3;
wire	[7:0] constant, NOOPWire, BranchedPCWire;
wire	[2:0] ALUOp;
wire	[1:0] R1_in, RegWin, ALU2,BSel;
wire	Nwire, Zwire, AddrSel;
reg		N, Z;
// ------------------------ Input Assignment ------------------------ //
assign	clock = KEY[1];
assign	reset =  ~KEY[0]; // KEY is active high


// ------------------- DE2 compatible HEX display ------------------- //
HEXs	HEX_display(
	.in0(reg0),.in1(reg1),.in2(reg2),.in3(reg3),.in4(NextCountwire),.selH({SW[2],SW[0]}),
	.out0(HEX0),.out1(HEX1),.out2(HEX2),.out3(HEX3),
	.out4(HEX4),.out5(HEX5)
);
// ----------------- END DE2 compatible HEX display ----------------- //

/*
// ------------------- DE1 compatible HEX display ------------------- //
chooseHEXs	HEX_display(
	.in0(reg0),.in1(reg1),.in2(reg2),.in3(reg3),f
	.out0(HEX0),.out1(HEX1),.select(SW[1:0])
);
// turn other HEX display off
assign HEX2 = 7'b1111111;
assign HEX3 = 7'b1111111;
assign HEX4 = 7'b1111111;
assign HEX5 = 7'b1111111;
assign HEX6 = 7'b1111111;
assign HEX7 = 7'b1111111;
// ----------------- END DE1 compatible HEX display ----------------- //
*/

FSM		Control(
	.reset(reset),.clock(clock),.N(N),.Z(Z),.Dinstr(DIR[3:0]),.RFinstr(RFIR[3:0]),.Xinstr(XIR[3:0]),.WBinstr(WBIR[3:0]),
	.PCwrite(PCWrite),.Countwrite(Countwrite),.AddrSel(AddrSel),.MemRead(MemRead),.MemWrite(MemWrite),.NOOPSel1(NOOPSel1),.S1Load(S1Load),.NOOPSel2(NOOPSel2),.S2Load(S2Load),
	.R1Sel(R1Sel),.RegWsel(RegWsel),.RFWrite(RFWrite),.R1B(R1B),.R2B(R2B),.NOOPSel3(NOOPSel3),.S3Load(S3Load),.FlagWrite(FlagWrite),.ALU3(ALU3),.NOOPSel4(NOOPSel4),.WBIRLoad(WBIRLoad),
	.ALU1(ALU1),.ALU2(ALU2),.ALUop(ALUOp),.IRMEMwire(IRMEMwire[3:0]),.Bsel(BSel)
);

/***********************STAGE 1 BEGIN*************************/

/*PCSel*/
mux2to1_8bit 		AddrSel_mux(
	.data0x(PC3wire),.data1x(NextPCwire),
	.sel(AddrSel),.result(AddrWire)
);

mux3to1_8bit 		BranchSel_mux(
	.data0x(PCwire),.data1x(BranchedPCWire),.data2x(PC4wire),
	.sel(BSel),.result(AddrWire2)
);

/*PC Reg*/
register_8bit	PC(
	.clock(clock),.aclr(reset),.enable(PCWrite),
	.data(AddrWire),.q(PCwire)
);

/* PC + 1 */
Adder		PCAdder(
	.in1(PCAdder1wire),.in2(PCAdder2wire),.out(NextPCwire)
);

/* Dual memory */
memory	DualMem(
	.MemRead(MemRead),.wren(MemWrite),.clock(clock),
	.address(R2wire),.data(R1wire),.q(MEMwire),.address_pc(AddrWire2),.q_pc(IRMEMwire) 
);

/* No-Op Mux 1 */ ///////////////////////Hardware Mod
mux2to1_8bit 		NOOPMux1(
	.data0x(IRMEMwire),.data1x(NOOPWire),
	.sel(NOOPSel1),.result(NOOPMuxWire1)
);

/* Decode IR */
register_8bit	DIR_reg(
	.clock(clock),.aclr(reset),.enable(S1Load),
	.data(NOOPMuxWire1),.q(DIR)
);

/*PC1*/
register_8bit	PC1(
	.clock(clock),.aclr(reset),.enable(S1Load),
	.data(AddrWire),.q(PC1wire)
);

/***********************STAGE 1 END*************************/

/***********************STAGE 2 BEGIN*************************/


/* No-Op Mux 2 */ ///////////////////////Hardware Mod
mux2to1_8bit 		NOOPMux2(
	.data0x(DIR),.data1x(NOOPWire),
	.sel(NOOPSel2),.result(NOOPMuxWire2)
);

/* RF IR */
register_8bit	RFIR_reg(
	.clock(clock),.aclr(reset),.enable(S2Load),
	.data(NOOPMuxWire2),.q(RFIR)
);

/*PC2*/
register_8bit	PC2(
	.clock(clock),.aclr(reset),.enable(S2Load),
	.data(PC1wire),.q(PC2wire)
);

/* Branch Adder */
Adder8b		BranchAdder(
	.in1(SE4wire),.in2(PC1wire),.out(BranchedPCWire)
);
/***********************STAGE 2 END*************************/

/***********************STAGE 3 BEGIN*************************/

/*OpA sel*/
mux2to1_2bit		R1Sel_mux(
	.data0x(RFIR[7:6]),.data1x(constant[1:0]),
	.sel(R1Sel),.result(R1_in)
);

/*RegW sel*/
mux2to1_2bit		RegW_mux(
	.data0x(constant[1:0]),.data1x(WBIR[7:6]),
	.sel(RegWsel),.result(RegWin)
);

/*Reg File*/
RF		RF_block(
	.clock(clock),.reset(reset),.RFWrite(RFWrite),
	.dataw(ALUOut),.reg1(R1_in),.reg2(RFIR[5:4]),
	.regw(RegWin),.data1(RFout1wire),.data2(RFout2wire),
	.r0(reg0),.r1(reg1),.r2(reg2),.r3(reg3)
);

/*Data1 out mux*/
mux2to1_8bit 		Data1(
	.data0x(ALUOut),.data1x(RFout1wire),
	.sel(R1B),.result(Data1Wire)
);

/*Data2 out mux*/
mux2to1_8bit 		Data2(
	.data0x(ALUOut),.data1x(RFout2wire),
	.sel(R2B),.result(Data2Wire)
);

/* No-Op Mux 3 */ ///////////////////////Hardware Mod
mux2to1_8bit 		NOOPMux3(
	.data0x(RFIR),.data1x(NOOPWire),
	.sel(NOOPSel3),.result(NOOPMuxWire3)
);

/* X IR */
register_8bit	XIR_reg(
	.clock(clock),.aclr(reset),.enable(S3Load),
	.data(NOOPMuxWire3),.q(XIR)
);
	
/*PC3*/
register_8bit	PC3(
	.clock(clock),.aclr(reset),.enable(S3Load),
	.data(PC2wire),.q(PC3wire)
);

/*OP A reg*/
register_8bit	R1(
	.clock(clock),.aclr(reset),.enable(S3Load),
	.data(Data1Wire),.q(R1wire)
);

/*OP B reg*/
register_8bit	R2(
	.clock(clock),.aclr(reset),.enable(S3Load),
	.data(Data2Wire),.q(R2wire)
);

/***********************STAGE 3 END*************************/

/***********************STAGE 4 BEGIN*************************/

/*ALU 1 MUX*/
mux2to1_8bit 		ALU1_mux(
	.data0x(ALUOut),.data1x(R1wire),
	.sel(ALU1),.result(ALU1wire)
);

/* ALU 2 MUX*/
mux4to1_8bit 		ALU2_mux(
	.data0x(R2wire),.data1x(ALUOut),
	.data2x(ZE5wire),.data3x(ZE3wire),.sel(ALU2),.result(ALU2wire)
);

/* ALU */
ALU		ALU(
	.in1(ALU1wire),.in2(ALU2wire),.out(ALUwire),
	.ALUOp(ALUOp),.N(Nwire),.Z(Zwire)
);

sExtend		SE4(.in(DIR[7:4]),.out(SE4wire));
zExtend		ZE3(.in(XIR[5:3]),.out(ZE3wire));
zExtend		ZE5(.in(XIR[7:3]),.out(ZE5wire));
// define parameter for the data size to be extended
defparam	SE4.n = 4;
defparam	ZE3.n = 3;
defparam	ZE5.n = 5;

/*ALU3_mux*/
mux2to1_8bit 		ALU3_mux(
	.data0x(ALUwire),.data1x(MEMwire),
	.sel(ALU3),.result(ALU3wire)
);

/* No-Op Mux 4 */ ///////////////////////Hardware Mod
mux2to1_8bit 		NOOPMux4(
	.data0x(XIR),.data1x(NOOPWire),
	.sel(NOOPSel4),.result(NOOPMuxWire4)
);

/* WB IR */
register_8bit	WBIR_reg(
	.clock(clock),.aclr(reset),.enable(WBIRLoad),
	.data(NOOPMuxWire4),.q(WBIR)
);
	

/*WB Reg*/
register_8bit	ALUOut_reg(
	.clock(clock),.aclr(reset),.enable(WBIRLoad),
	.data(ALU3wire),.q(ALUOut)
);

/*PC4*/
register_8bit	PC4(
	.clock(clock),.aclr(reset),.enable(WBIRLoad),
	.data(PC3wire),.q(PC4wire)
);


/***********************STAGE 4 END*************************/

/* counter Adder */
Adder		CountAdder(
	.in1(CountAdder1wire),.in2(CountAdder2wire),.out(NextCountwire)
);

/* counter reg*/
register_16bit	Count_reg(
	.clock(clock),.aclr(reset),.enable(Countwrite),
	.data(NextCountwire),.q(CountOut)
);




always@(posedge clock or posedge reset)
begin
if (reset)
	begin
	N <= 0;
	Z <= 0;
	end
else
if (FlagWrite)
	begin
	N <= Nwire;
	Z <= Zwire;
	end
end

// ------------------------ Assign Constant 1 ----------------------- //
assign	constant = 1;
//-----------------------Assign Count Adder wires-------------------- //
assign CountAdder1wire = CountOut ;
assign CountAdder2wire = 1;
assign PCAdder1wire = AddrWire2;
assign PCAdder2wire = 1;
assign NOOPWire = 8'b00001010;

// ------------------------- LEDs Indicator ------------------------- //
always @ (*)
begin
    case({SW[4],SW[3]})
    2'b00:
    begin
      LEDR[9] <= Countwrite;
      LEDR[8] <= PCWrite;
      LEDR[7] <= AddrSel;
      LEDR[6] <= S1Load;
      LEDR[5] <= NOOPSel1;
      LEDR[4:3] <= BSel;
      LEDR[2] <= 0;
      LEDR[1] <= S2Load;
      LEDR[0] <= NOOPSel2;
    end

    2'b01:
    begin
      LEDR[9] <= ALU1;
      LEDR[8:7] <= ALU2;
      LEDR[6:4] <= ALUOp;
      LEDR[3] <= FlagWrite;
		LEDR[2] <= ALU3;
      LEDR[1] <= S3Load;
      LEDR[0] <= NOOPSel3;
    end

    2'b10:
    begin
      LEDR[9] <= WBIRLoad;
      LEDR[8] <= NOOPSel4;
      LEDR[7] <= MemRead;
      LEDR[6] <= MemWrite;
      LEDR[5] <= RegWsel;
      LEDR[4] <= RFWrite;
		LEDR[3] <= 1'b0;
		LEDR[2] <= 1'b0;
		LEDR[1] <= 1'b0;
		LEDR[0] <= 1'b0;
    end

    2'b11:
    begin
      LEDR[9:0] = 10'b0;
    end
  endcase

end
endmodule
