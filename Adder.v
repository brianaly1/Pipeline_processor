// ---------------------------------------------------------------------
// Copyright (c) 2007 by University of Toronto ECE 243 development team 
// ---------------------------------------------------------------------
//
// Major Functions:	Mathematical Operator which calculates two inputs.
//					This operator performs five operations:	i) addition,
//					ii) subtraction, iii) oring, iv) nand, v) shift
// 
// Input(s):		1. in1: first eight-bit input data to be operated
//					2. in2: second eight-bit input data to be operated
//					3. ALUOp: select signal indicates operation to be
//							  performed
//
// Output(s):		1. out:	output value after performing mathematical
//							operation
//					2. N: a single bit indicates whether an output is
//						  negative or non-negative
//					3. Z: a single bit indicates whether an output is
//						  zero or non-zero
//
// ---------------------------------------------------------------------

module Adder (in1, in2, out);

// ------------------------ PORT declaration ------------------------ //
input [15:0] in1, in2;
output [15:0] out;

// ------------------------- Registers/Wires ------------------------ //
reg [15:0] tmp_out;

// -------------------------- ALU Operation ------------------------- //
// ALUOp encoding:													  //
//  000 = addition, 001 = subtraction, 010 = OR,					  //
//  011 = NAND, and 100 = Shift										  //
// ------------------------------------------------------------------ //
always @(*)
begin

	tmp_out = in1 + in2;
	
end

// Assign output and condition flags
assign out = tmp_out;

endmodule
