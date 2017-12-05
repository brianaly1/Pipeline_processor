// ---------------------------------------------------------------------
// Copyright (c) 2007 by University of Toronto ECE 243 development team 
// ---------------------------------------------------------------------
//
// Major Functions:	control processor's datapath
// 
// Input(s):	1. instr[3:0]: input is used to determine states
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
MemRead, MemWrite, S1Load, S2Load, R1Sel, RegWsel, RFWrite, R1B, M1,M2,
R2B, S3Load, FlagWrite, ALU3, WBIRLoad, ALU1, ALU2, ALUop,NOOPSel1,NOOPSel2,NOOPSel3,NOOPSel4,IRMEMwire,Bsel
//, state
);
	input		[7:0] Dinstr,RFinstr,Xinstr,WBinstr;
	input 	[3:0]	IRMEMwire;
	input				N, Z;
	input				reset, clock;
	output			PCwrite, Countwrite, MemRead, MemWrite, NOOPSel1, S1Load, NOOPSel2, S2Load; 
	output			R1Sel, RegWsel, RFWrite, R1B, R2B, M1, M2, NOOPSel3, S3Load, ALU1, FlagWrite, ALU3, NOOPSel4, WBIRLoad;
	output	[1:0] ALU2,Bsel;
	output	[2:0] ALUop;
	//output	[3:0] state;
	
	reg 		[4:0]	stage1,stage2,stage3,stage4,stage5;
	reg		[2:0] state;
	reg				PCwrite, Countwrite, MemRead, MemWrite, NOOPSel1, S1Load, NOOPSel2, S2Load, s3haz1, s3haz2, s4haz1, s4haz2,memhaz1,memhaz2;
	reg				R1Sel, RegWsel, RFWrite, R1B, R2B, M1, M2, NOOPSel3, S3Load, ALU1, FlagWrite, ALU3, NOOPSel4, WBIRLoad;
	reg		[1:0] ALU2,Bsel;
	reg		[2:0] ALUop;
	
	
	// stage constants
	parameter [4:0] s1 = 0, s1b = 1, s2 = 2, s3_LStASuNaSh = 3,
					s3_Ori = 4, s3_noop = 5, s4_Load = 6, s4_Store = 7, 
					s4_Add = 8, s4_Sub = 9, s4_Nand = 10, s4_Ori = 11, 
					s4_Shift = 12, s4_noop = 13, s5_most = 14, s5_noop= 15, 
					s5_ori=16;
	// state constants
	parameter [2:0] reset_s = 0, normal_op = 1, b_fail = 2, stop = 3;

	
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
									if(Xinstr[3:0] == 4'b1101 & N) state = b_fail;
									else if(Xinstr[3:0] == 4'b0101 & !Z) state = b_fail;
									else if(Xinstr[3:0] == 4'b1001 & Z) state = b_fail;
									else if(Dinstr[3:0] == 4'b0001)	state = stop;
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
			reset: begin
						s3haz1 = 0;
						s3haz2 = 0;
						s4haz1 = 0;
						s4haz2 = 0;
					 end
					 
			normal_op:	begin	
								
								if(Dinstr[3:0] ==  4'b1101 | Dinstr[3:0]  == 4'b0101 | Dinstr[3:0]  == 4'b1001)
									stage1 = s1b;
								else
									stage1 = s1;
								stage2 = s2;
								
								/***************STAGE 3 LOGIC************/
								if(RFinstr[3:0] == 4'b0000 | RFinstr[3:0] == 4'b0010 | RFinstr[3:0] == 4'b0100 | RFinstr[3:0] == 4'b0110 | RFinstr[3:0] == 4'b1000)	
									begin
										stage3 = s3_LStASuNaSh;
										if(WBinstr[3:0] == 4'b0000 | WBinstr[3:0] == 4'b0100 | WBinstr[3:0] == 4'b0110 | WBinstr[3:0] == 4'b1000 | WBinstr[2:0] == 3'b011)
											begin
												if(RFinstr[7:6] == WBinstr[7:6]) s3haz1 = 1;
												else s3haz1 = 0;
												if(RFinstr[5:4] == WBinstr[7:6]) s3haz2 = 1;
												else	s3haz2 = 0;
											end
										else if(WBinstr[2:0] == 3'b111)
											begin
												if(RFinstr[7:6] == 2'b01) s3haz1 = 1;
												else s3haz1 = 0;
												if(RFinstr[5:4] == 2'b01) s3haz2 = 1;
												else	s3haz2 = 0;
											end
										else 	begin	
												s3haz1 = 0;
												s3haz2 = 0;
												end
									end
									
								else if (RFinstr[2:0] == 3'b011)
									begin
										stage3 = s3_LStASuNaSh;
										s3haz2 = 0;
										if(WBinstr[3:0] == 4'b0000 | WBinstr[3:0] == 4'b0100 | WBinstr[3:0] == 4'b0110 | WBinstr[3:0] == 4'b1000 | WBinstr[2:0] == 3'b011)
											begin
												if(RFinstr[7:6] == WBinstr[7:6]) s3haz1 = 1;
												else s3haz1 = 0;
											end
										else if(WBinstr[2:0] == 3'b111 & RFinstr[7:6] == 2'b01) s3haz1 = 1;
										else 	s3haz1 = 0;
									end								
								else if( RFinstr[2:0] == 3'b111) 
									begin
										stage3 = s3_Ori;
										s3haz2 = 0;
										if(WBinstr[3:0] == 4'b0000 | WBinstr[3:0] == 4'b0100 | WBinstr[3:0] == 4'b0110 | WBinstr[3:0] == 4'b1000 | WBinstr[2:0] == 3'b011)
											begin
												if(WBinstr[7:6] == 2'b01) s3haz1 = 1;
												else s3haz1 = 0;
											end
										else if(WBinstr[2:0] == 3'b111) s3haz1 = 1;
										else 	s3haz1 = 0;
									end
								else if( RFinstr[3:0] == 4'b1010 ) 
									begin
										stage3 = s3_noop;
										s3haz1 = 0;
										s3haz2 = 0;
									end
								
								else
									begin	
										stage3 = s3_noop;
										s3haz1 = 0;
										s3haz2 = 0;
									end
									
								/***************STAGE 4 LOGIC************/
								if(Xinstr[3:0] == 4'b0000) stage4 = s4_Load;
								else if(Xinstr[3:0] == 4'b0010) stage4 = s4_Store;
								else if(Xinstr[3:0] == 4'b0100) stage4 = s4_Add;
								else if(Xinstr[3:0] == 4'b0110) stage4 = s4_Sub;
								else if(Xinstr[3:0] == 4'b1000 )stage4 = s4_Nand;
								else if(Xinstr[2:0] == 3'b111) stage4 = s4_Ori;
								else if(Xinstr[2:0] == 3'b011) stage4 = s4_Shift;
								else if(Xinstr[3:0] == 4'b1010) stage4 = s4_noop;
								else	stage4 = s4_noop; // encompasses branches too
								
								if(Xinstr[3:0] == 4'b0100 | Xinstr[3:0] == 4'b0110 | Xinstr[3:0] == 4'b1000)	
									begin
										if(WBinstr[3:0] == 4'b0000 | WBinstr[3:0] == 4'b0100 | WBinstr[3:0] == 4'b0110 | WBinstr[3:0] == 4'b1000 | WBinstr[2:0] == 3'b011)
											begin
												if(Xinstr[7:6] == WBinstr[7:6]) s4haz1 = 1;
												else s4haz1 = 0;
												if(Xinstr[5:4] == WBinstr[7:6]) s4haz2 = 1;
												else	s4haz2 = 0;
											end
									
										else if(WBinstr[2:0] == 3'b111)
											begin
												if(Xinstr[7:6] == 2'b01) s4haz1 = 1;
												else s4haz1 = 0;
												if(Xinstr[5:4] == 2'b01) s4haz2 = 1;
												else	s4haz2 = 0;
											end
										else 	begin	
													s4haz1 = 0;
													s4haz2 = 0;
												end
									end 
								
								else if(Xinstr[2:0] == 3'b011) //shift
									begin
										s4haz2 = 0;
										if(WBinstr[3:0] == 4'b0000 | WBinstr[3:0] == 4'b0100 | WBinstr[3:0] == 4'b0110 | WBinstr[3:0] == 4'b1000 | WBinstr[2:0] == 3'b011)
											begin
												if(Xinstr[7:6] == WBinstr[7:6]) s4haz1 = 1;
												else s4haz1 = 0;
											end
										else if(WBinstr[2:0] == 3'b111 & Xinstr[7:6] == 2'b01) s4haz1 = 1;
										else 	s4haz1 = 0;
									end	
									
								else if(Xinstr[3:0] == 4'b0000) //load
									begin
										memhaz2 = 0;
										if(WBinstr[3:0] == 4'b0000 | WBinstr[3:0] == 4'b0100 | WBinstr[3:0] == 4'b0110 | WBinstr[3:0] == 4'b1000 | WBinstr[2:0] == 3'b011)
											begin
												if(Xinstr[5:4] == WBinstr[7:6]) memhaz1 = 1;
												else memhaz1 = 0;
											end
										else if(WBinstr[2:0] == 3'b111 & Xinstr[5:4] == 2'b01) memhaz1 = 1;
										else 	memhaz1 = 0;
									end	
									
								else if(Xinstr[3:0] == 3'b0010) //store
									begin
										if(WBinstr[3:0] == 4'b0000 | WBinstr[3:0] == 4'b0100 | WBinstr[3:0] == 4'b0110 | WBinstr[3:0] == 4'b1000 | WBinstr[2:0] == 3'b011)
											begin
												if(Xinstr[7:6] == WBinstr[7:6]) memhaz2 = 1;
												else memhaz2 = 0;
												if(Xinstr[5:4] == WBinstr[7:6]) memhaz1 = 1;
												else	memhaz1 = 0;
											end
										else if(WBinstr[2:0] == 3'b111)
											begin
												if(Xinstr[7:6] == 2'b01) memhaz2 = 1;
												else memhaz2 = 0;
												if(Xinstr[5:4] == 2'b01) memhaz1 = 1;
												else	memhaz1 = 0;
											end
											
										else 	s4haz1 = 0;
									end	
								
								else if(Xinstr[2:0] == 3'b111) //ori
									begin
										s4haz2 = 0;
										if(WBinstr[3:0] == 4'b0000 | WBinstr[3:0] == 4'b0100 | WBinstr[3:0] == 4'b0110 | WBinstr[3:0] == 4'b1000 | WBinstr[2:0] == 3'b011)
											begin
												if(WBinstr[7:6] == 2'b01) s4haz1 = 1;
												else s4haz1 = 0;
											end
										else if(WBinstr[2:0] == 3'b111) s4haz1 = 1;
										else 	s4haz1 = 0;
									end
								else 	begin //add memory forwarding logic after modifying the datapath.
											s4haz1 = 0;
											s4haz2 = 0;
										end
								/***************STAGE 5 LOGIC************/
								if(WBinstr[3:0] == 4'b0000 | WBinstr[3:0] == 4'b0100 | WBinstr[3:0] == 4'b0110 | WBinstr[3:0] == 4'b1000 | WBinstr[2:0] == 3'b011) stage5 = s5_most;
								else if(WBinstr[2:0] == 3'b111) stage5 = s5_ori; 
								else if( WBinstr[3:0] == 4'b1101 | WBinstr[3:0] == 4'b0101 | WBinstr[3:0] == 4'b1001 | WBinstr[3:0] == 4'b0010 | WBinstr[3:0] == 4'b1010) stage5 = s5_noop;
								else stage5 = s5_noop;		
				
								
							end	
				default: 
					begin
						s3haz1 = 0;
						s3haz2 = 0;
						s4haz1 = 0;
						s4haz2 = 0;
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
					S1Load = 1;
					NOOPSel1 = 0;
					Bsel = 2'b00;
				
				/********stage 2 flush signals********/
					S2Load = 1;
					NOOPSel2 = 1;
				
				/********stage 3 flush signals********/
					R1Sel = 0; //x 
					R1B = 1; //x
					R2B = 1; //x
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
					M1 = 1;
					M2 = 1;
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
									Bsel = 2'b00;
									S1Load = 1;
								end
								
						s1b:	begin
									PCwrite = 1;
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
												R1B = !s3haz1;
												R2B = !s3haz2;
												S3Load = 1;
											end
											
						s3_Ori:			begin
												R1Sel = 1;
												R1B = !s3haz1;
												R2B = !s3haz2;
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
											M1 = !memhaz1;
											M2 = !memhaz2;
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
											M1 = !memhaz1;
											M2 = !memhaz2;													
										end
										
						s4_Add:		begin
											ALU1 = !s4haz1;
											ALU2 = (!s4haz2) ? 2'b00 : 2'b01; 
											ALUop = 3'b000; 
											FlagWrite = 1;
											ALU3 = 0;
											MemWrite = 0;
											WBIRLoad = 1;
											M1 = !memhaz1;
											M2 = !memhaz2;
										end
										
						s4_Sub:		begin	
											ALU1 = !s4haz1; 
											ALU2 = (!s4haz2) ? 2'b00 : 2'b01; 
											ALUop = 3'b001; 
											FlagWrite = 1;
											ALU3 = 0;
											MemWrite = 0;
											MemRead = 0;
											WBIRLoad = 1;
											M1 = !memhaz1;
											M2 = !memhaz2;
										end
											
						s4_Nand:		begin	
											ALU1 = !s4haz1; 
											ALU2 = (!s4haz2) ? 2'b00 : 2'b01; 
											ALUop = 3'b011; 
											FlagWrite = 1;
											ALU3 = 0;
											MemWrite = 0;
											MemRead = 0;
											WBIRLoad = 1;
											M1 = !memhaz1;
											M2 = !memhaz2;
										end
							
						s4_Ori:		begin	
											ALU1 = !s4haz1; 
											ALU2 = (!s4haz2) ? 2'b10 : 2'b01; 
											ALUop = 3'b010; 
											FlagWrite = 1;
											ALU3 = 0;
											MemWrite = 0;
											MemRead = 0;
											WBIRLoad = 1;
											M1 = !memhaz1;
											M2 = !memhaz2;
										end
						
						s4_Shift:	begin	
											ALU1 = !s4haz1; 
											ALU2 = (!s4haz2) ? 2'b11 : 2'b01;  
											ALUop = 3'b100; 
											FlagWrite = 1;
											ALU3 = 0;
											MemWrite = 0;
											MemRead = 0;
											WBIRLoad = 1;
											M1 = !memhaz1;
											M2 = !memhaz2;
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
											M1 = !memhaz1;
											M2 = !memhaz2;
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
					S1Load = 1;
					NOOPSel1 = 0;
					Bsel = 2'b10;
				
				/********stage 2 flush signals********/
					S2Load = 1;
					NOOPSel2 = 1;
				
				/********stage 3 flush signals********/
					R1Sel = 0; //x 
					R1B = 1; //x
					R2B = 1; //x
					S3Load = 1;
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
					M1 = 1;
					M2 = 1;			
				/********stage 5 noop signals********/
					RegWsel = 0; //x
					RFWrite = 0;
					
				end 
			stop: //no need for stage case cause only one possible case for each stage here
				begin
					Countwrite = 0;
				/********stage 1 flush signals********/
					PCwrite = 0;
					S1Load = 1;
					NOOPSel1 = 1;
					Bsel = 2'b00;
				/********stage 2 flush signals********/
					S2Load = 1;
					NOOPSel2 = 1;
				
				/********stage 3 flush signals********/
					R1Sel = 0; //x 
					R1B = 1; //x
					R2B = 1; //x
					S3Load = 1;
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
					M1 = 1;
					M2 = 1;			
				/********stage 5 noop signals********/
					RegWsel = 0; //x
					RFWrite = 0;
				
				end

			default:	
				begin
					Countwrite = 1;
				/********stage 1 signals********/
					PCwrite = 1;
					S1Load = 1;
					NOOPSel1 = 0;
					Bsel = 2'b00;
				/********stage 2 flush signals********/
					S2Load = 1;
					NOOPSel2 = 1;
				
				/********stage 3 flush signals********/
					R1Sel = 0; //x 
					R1B = 1; //x
					R2B = 1; //x
					S3Load = 1;
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
					M1 = 1;
					M2 = 1;			
				/********stage 5 noop signals********/
					RegWsel = 0; //x
					RFWrite = 0;

				end
		endcase
	end
	
endmodule
