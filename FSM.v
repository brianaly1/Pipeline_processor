// ---------------------------------------------------------------------
// Copyright (c) 2007 by University of Toronto ECE 243 development team 
// ---------------------------------------------------------------------
//
// Major Functions:	control processor's datapath
// 
// Input(s):	1. instr: input is used to determine states
//				2. N: if branches, input is used to determine if
//					  negative condition is true
//				3. Z: if branches, input is used to determine if 
//					  zero condition is true
//
// Output(s):	control signals
//
//				** More detail can be found on the course note under
//				   "Multi-Cycle Implementation: The Control Unit"
//
// ---------------------------------------------------------------------

module FSM(
reset, clock, N, Z, Dinstr, RFinstr, Xinstr, WBinstr, PCwrite, Countwrite, 
AddrSel, MemRead, MemWrite, S1Load, S2Load, R1Sel, RegWsel, RFWrite, R1B,
R2B, S3Load, FlagWrite, ALU3, WBIRLoad, ALU1, ALU2, ALUop,NOOPSel1,NOOPSel2,NOOPSel3,NOOPSel4,IRMEMwire,Bsel 
//, state
);
	input		[3:0] Dinstr,RFinstr,Xinstr, WBinstr,IRMEMwire;
	input				N, Z;
	input				reset, clock;
	output			PCwrite, Countwrite, MemRead, MemWrite, NOOPSel1, S1Load, NOOPSel2, S2Load; 
	output			R1Sel, RegWsel, RFWrite, R1B, R2B, NOOPSel3, S3Load, ALU1, FlagWrite, ALU3, NOOPSel4, WBIRLoad, AddrSel;
	output	[1:0] ALU2,Bsel;
	output	[2:0] ALUop;
	//output	[3:0] state;
	
	reg 		[4:0]	stage1,stage2,stage3,stage4,stage5;
	reg		[2:0] state;
	reg				PCwrite, Countwrite, MemRead, MemWrite, NOOPSel1, S1Load, NOOPSel2, S2Load;
	reg				R1Sel, RegWsel, RFWrite, R1B, R2B, NOOPSel3, S3Load, ALU1, FlagWrite, ALU3, NOOPSel4, WBIRLoad, AddrSel;
	reg		[1:0] ALU2,Bsel;
	reg		[2:0] ALUop;
	
	
	// stage constants
	parameter [4:0] s1 = 0, s1b = 1, s2 = 2, s3_LStASuNaSh = 3,
					s3_Ori = 4, s3_noop = 5, s4_Load = 6, s4_Store = 7, 
					s4_Add = 8, s4_Sub = 9, s4_Nand = 10, s4_Ori = 11, 
					s4_Shift = 12, s4_noop = 13, s5_most = 14, s5_noop= 15, s5_ori=16;
	// state constants
	parameter [2:0] reset_s = 0, normal_op = 1, b_fail = 2, stop = 3 ;
	
	// determines the next state based upon the current state; supports
	// asynchronous reset
	always @(posedge clock or posedge reset)
	begin
		if (reset) state = reset_s;
		else
		begin
			case(state)
				reset_s:	state = normal_op;				
			
				normal_op:	begin
									/***************STATE LOGIc**************/
									if(Xinstr == 4'b1101 & N) state = b_fail;
									else if(Xinstr == 4'b0101 & !Z) state = b_fail;
									else if(Xinstr == 4'b1001 & Z) state = b_fail;
									else if(Dinstr == 4'b0001)	state = stop;
									else state = normal_op; //will add more cases based on Dinstr for data hazard forwarding later	
								end
								
				b_fail:		state = normal_op;
								
				stop:			state = stop;
									
			endcase
		end
	end
	always @(*)
	begin
		case(state)						
			normal_op:	begin	
								
								if(Dinstr ==  4'b1101 | Dinstr  == 4'b0101 | Dinstr  == 4'b1001)
									stage1 = s1b;
								else
									stage1 = s1;
								stage2 = s2;
								/***************STAGE 3 LOGIC************/
								if(RFinstr == 4'b0000 | RFinstr == 4'b0010 | RFinstr == 4'b0100 | RFinstr == 4'b0110 | RFinstr == 4'b1000 | RFinstr[2:0] == 3'b011)	
									stage3 = s3_LStASuNaSh;
								else if( RFinstr[2:0] == 3'b111) stage3 = s3_Ori;
								else if( RFinstr == 4'b1010 ) stage3 = s3_noop;
								else stage3 = s3_noop;
							
								/***************STAGE 4 LOGIC************/
								if(Xinstr == 4'b0000) stage4 = s4_Load;
								else if(Xinstr == 4'b0010) stage4 = s4_Store;
								else if(Xinstr == 4'b0100) stage4 = s4_Add;
								else if(Xinstr == 4'b0110) stage4 = s4_Sub;
								else if(Xinstr == 4'b1000 )stage4 = s4_Nand;
								else if(Xinstr[2:0] == 3'b111) stage4 = s4_Ori;
								else if(Xinstr[2:0] == 3'b011) stage4 = s4_Shift;
								else if(Xinstr == 4'b1010) stage4 = s4_noop;
								else	stage4 = s4_noop; // encompasses branches too
								
								/***************STAGE 5 LOGIC************/
								if(WBinstr == 4'b0000 | WBinstr == 4'b0100 | WBinstr == 4'b0110 | WBinstr == 4'b1000 | WBinstr[2:0] == 3'b011) stage5 = s5_most;
								else if(WBinstr[2:0] == 3'b111) stage5 = s5_ori; 
								else if( WBinstr == 4'b1101 | WBinstr == 4'b0101 | WBinstr == 4'b1001 | WBinstr == 4'b0010 | WBinstr == 4'b1010) stage5 = s5_noop;
								else stage5 = s5_noop;						
							end	
		endcase
	end
	
	// sets the control sequences based upon the current state and instruction
	always @(*)
	begin
		case (state) //no need for stage case cause only one possible case for each stage here
			reset_s:	
				begin
					Countwrite = 1;
				/********stage 1 signals********/
					PCwrite = 1;
					AddrSel = 1;
					S1Load = 1;
					NOOPSel1 = 0;
					Bsel = 2'b00;
				
				/********stage 2 flush signals********/
					S2Load = 1;
					NOOPSel2 = 1;
				
				/********stage 3 flush signals********/
					ALU1 = 0; //x
					ALU2 = 0; //x
					ALUop = 0; //x
					FlagWrite = 0;
					ALU3 = 0; //x
					S3Load = 1;
					NOOPSel3 = 1;
				
				/********stage 4 flush signals********/
					ALU1 = 0; //x
					ALU2 = 0; //x
					ALUop = 0; //x
					FlagWrite = 0;
					ALU3 = 0; //x
					WBIRLoad = 1;
					NOOPSel4 = 1;
					MemRead = 0;
					MemWrite = 0;
				
				/********stage 5 noop signals********/
					RegWsel = 0; //x
					RFWrite = 0;
				
				end	
				
			normal_op: 	
				begin
					NOOPSel1 = 0;
					NOOPSel2 = 0;
					NOOPSel3 = 0;
					NOOPSel4 = 0;
					Countwrite = 1;
					case (stage1)
						s1:	begin
									PCwrite = 1;
									AddrSel = 1;
									Bsel = 2'b00;
									S1Load = 1;
								end
								
						s1b:	begin
									PCwrite = 1;
									AddrSel = 1;
									Bsel = 2'b01;
									S1Load = 1;
								end
					endcase
					
					case (stage2)
						s2:	S2Load = 1;
					endcase
					
					case (stage3)
						s3_LStASuNaSh:	begin
												R1Sel = 0;
												R1B = 1;
												R2B = 1;
												S3Load = 1;
											end
											
						s3_Ori:			begin
												R1Sel = 1;
												R1B = 1;
												R2B = 1;
												S3Load = 1;
											end
											
						s3_noop:			begin
												R1Sel = 0; //x 
												R1B = 0; //x
												R2B = 0; //x
												S3Load = 1;
											end
					endcase
					
					case (stage4)
						s4_Load:		begin
											ALU1 = 0; //x
											ALU2 = 0; //x
											ALUop = 0; //x
											FlagWrite = 0;
											ALU3 = 1;
											MemRead = 1;
											MemWrite = 0;
											WBIRLoad = 1;
										end
										
						s4_Store:	begin	
											ALU1 = 0; //x
											ALU2 = 0; //x
											ALUop = 0; //x
											FlagWrite = 0;
											ALU3 = 0;
											MemWrite = 1;
											MemRead = 0;
											WBIRLoad = 1;
										end
										
						s4_Add:		begin
											ALU1 = 1; 
											ALU2 = 2'b00; 
											ALUop = 3'b000; 
											FlagWrite = 1;
											ALU3 = 0;
											MemWrite = 0;
											WBIRLoad = 1;
										end
										
						s4_Sub:		begin	
											ALU1 = 1; 
											ALU2 = 2'b00; 
											ALUop = 3'b001; 
											FlagWrite = 1;
											ALU3 = 0;
											MemWrite = 0;
											MemRead = 0;
											WBIRLoad = 1;
										end
											
						s4_Nand:		begin	
											ALU1 = 1; 
											ALU2 = 2'b00; 
											ALUop = 3'b011; 
											FlagWrite = 1;
											ALU3 = 0;
											MemWrite = 0;
											MemRead = 0;
											WBIRLoad = 1;
										end
							
						s4_Ori:		begin	
											ALU1 = 1; 
											ALU2 = 2'b10; 
											ALUop = 3'b010; 
											FlagWrite = 1;
											ALU3 = 0;
											MemWrite = 0;
											MemRead = 0;
											WBIRLoad = 1;
										end
						
						s4_Shift:	begin	
											ALU1 = 1; 
											ALU2 = 2'b11; 
											ALUop = 3'b100; 
											FlagWrite = 1;
											ALU3 = 0;
											MemWrite = 0;
											MemRead = 0;
											WBIRLoad = 1;
										end
										
						s4_noop:		begin	
											ALU1 = 0; //x
											ALU2 = 0; //x
											ALUop = 0; //x
											FlagWrite = 0;
											ALU3 = 0; //x
											MemWrite = 0;
											MemRead = 0;
											WBIRLoad = 1;
										end
					endcase
					
					case (stage5)
						s5_most:		begin	
											RegWsel = 1;
											RFWrite = 1;
										end
										
						s5_ori:		begin	
											RegWsel = 0;
											RFWrite = 1;
										end
						
						s5_noop:		begin
											RegWsel = 0; //x
											RFWrite = 0;
										end
					endcase
				
				end	
			b_fail: //no need for stage case cause only one possible case for each stage here
				begin
					Countwrite = 1;
				/********stage 1 signals********/
					PCwrite = 1;
					AddrSel = 1;
					S1Load = 1;
					NOOPSel1 = 0;
					Bsel = 2'b10;
				
				/********stage 2 flush signals********/
					S2Load = 1;
					NOOPSel2 = 1;
				
				/********stage 3 flush signals********/
					ALU1 = 0; //x
					ALU2 = 0; //x
					ALUop = 0; //x
					FlagWrite = 0;
					ALU3 = 0; //x
					WBIRLoad = 1;
					NOOPSel3 = 1;
				
				/********stage 4 flush signals********/
					ALU1 = 0; //x
					ALU2 = 0; //x
					ALUop = 0; //x
					FlagWrite = 0;
					ALU3 = 0; //x
					MemWrite = 0;
					MemRead = 0;
					WBIRLoad = 1;
					NOOPSel4 = 1;
				
				/********stage 5 noop signals********/
					RegWsel = 0; //x
					RFWrite = 0;
					
				end 
			stop: //no need for stage case cause only one possible case for each stage here
				begin
					Countwrite = 0;
				/********stage 1 flush signals********/
					PCwrite = 0;
					AddrSel = 1;
					S1Load = 1;
					NOOPSel1 = 1;
					Bsel = 2'b00;
				/********stage 2 flush signals********/
					S2Load = 1;
					NOOPSel2 = 1;
				
				/********stage 3 flush signals********/
					ALU1 = 0; //x
					ALU2 = 0; //x
					ALUop = 0; //x
					FlagWrite = 0;
					ALU3 = 0; //x
					WBIRLoad = 1;
					NOOPSel3 = 1;
				
				/********stage 4 flush signals********/
					ALU1 = 0; //x
					ALU2 = 0; //x
					ALUop = 0; //x
					FlagWrite = 0;
					ALU3 = 0; //x
					MemWrite = 0;
					MemRead = 0;
					WBIRLoad = 1;
					NOOPSel4 = 1;
				
				/********stage 5 noop signals********/
					RegWsel = 0; //x
					RFWrite = 0;
				
				end

			default:	
				begin
					Countwrite = 1;
				/********stage 1 signals********/
					PCwrite = 1;
					AddrSel = 1;
					S1Load = 1;
					NOOPSel1 = 0;
					Bsel = 2'b00;
				/********stage 2 flush signals********/
					S2Load = 1;
					NOOPSel2 = 1;
				
				/********stage 3 flush signals********/
					ALU1 = 0; //x
					ALU2 = 0; //x
					ALUop = 0; //x
					FlagWrite = 0;
					ALU3 = 0; //x
					WBIRLoad = 1;
					NOOPSel3 = 1;
				
				/********stage 4 flush signals********/
					ALU1 = 0; //x
					ALU2 = 0; //x
					ALUop = 0; //x
					FlagWrite = 0;
					ALU3 = 0; //x
					MemWrite = 0;
					MemRead = 0;
					WBIRLoad = 1;
					NOOPSel4 = 1;
				
				/********stage 5 noop signals********/
					RegWsel = 0; //x
					RFWrite = 0;

				end
		endcase
	end
	
endmodule
