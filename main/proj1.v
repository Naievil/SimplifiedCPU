module tb_proj1;
reg clk, rst;
wire MemRW_IO;
wire [7:0]MemAddr_IO;
wire [15:0]MemD_IO;

	proj1 dut(clk, rst, MemRW_IO, MemAddr_IO, MemD_IO);

always
 #5 clk = !clk;

initial begin
clk=1'b0;
rst=1'b1;
$readmemh("memory.list", tb_proj1.dut.ram_ins.mem256x16);
#20 rst=1'b0;
#435
$display("Final value\n");
$display("0x00d %d\n",tb_proj1.dut.ram_ins.mem256x16[16'h000d]);
$finish;
end

endmodule

module proj1(
 clk,
 rst,
 MemRW_IO,
 MemAddr_IO,
 MemD_IO
 );
 input clk;
 input rst;
 output MemRW_IO;
 output [7:0] MemAddr_IO;
 output [15:0]MemD_IO;
 wire    [15:0]MemD; 

 wire [7:0] MemAddr;
 wire [15:0] MemQ;
 wire zflag;
 wire [7:0] opcode;
 wire muxPC, muxMAR, muxACC, loadMAR, loadPC,
     loadACC, loadMDR, loadIR, MemRW; 
 wire [1:0] opALU;

//one instance of memory
	ram ram_ins(MemRW, MemD, MemQ, MemAddr);


//one instance of controller
	ctr ctr_main(clk, rst, zflag, opcode,
		      	muxPC, muxMAR, muxACC, loadMAR, loadPC, 
				loadACC, loadMDR, loadIR, opALU, MemRW);

//one instance of datapath1
	datapath datapath(clk, rst, muxPC, muxMAR, muxACC, loadMAR,
 				loadPC, loadACC, loadMDR, loadIR, opALU,
 				zflag, opcode, MemAddr, MemD, MemQ);


endmodule

//The memory module
// ******************************
//           COMPLETE
// ******************************
module ram(
 we,
 d,
 q,
 addr
 );

input we;
input [15:0]  d;
output reg [15:0] q;
input [7:0] addr;

reg [15:0] mem256x16 [0:255];

//We => 1 bit read / write enable
//D => 16 bit data input
//Q => 16 bit data output
//Addr => 8 bit input address 
// WE => 0 read, 1 write

always @(*) begin
	if (we) begin
		mem256x16[addr] = d;
	end else begin
		q = mem256x16[addr];
	end

end

endmodule 

// Arithmetic Logic Unit
// ******************************
//           COMPLETE
// ******************************
module alu(
 A,
 B,
 opALU,
 Rout
);

input [15:0] A;
input [15:0] B;
input [1:0]opALU;
output reg [15:0] Rout;

//A => 16 bit input 1
//B => 16 bit input 2
//opALU => 1 bit input
// 1 A + B
// 0 A ^ B
//Rout => 16 bit output 

always @(*) begin
if (opALU == 2'b01) begin
	Rout <= (A + B);
end else if (opALU == 2'b00) begin
	Rout <= (A ^ B);
end else if (opALU == 2'b10) begin
	Rout <= (A - B);
end else if (opALU == 2'b11) begin
	Rout <= (A & B);
end
end

endmodule 

// Controller
// ******************************
//           COMPLETE
// ******************************
module ctr (
 clk,
 rst,
 zflag,
 opcode,
 muxPC,
 muxMAR,
 muxACC,
 loadMAR,
 loadPC,
 loadACC,
 loadMDR,
 loadIR,
 opALU,
 MemRW
);
 input clk;
 input rst;
 input zflag;
 input [7:0]opcode;
 output reg muxPC;
 output reg muxMAR;
 output reg muxACC;
 output reg loadMAR;
 output reg loadPC;
 output reg loadACC;
 output reg loadMDR;
 output reg loadIR;
 output reg [1:0] opALU;
 output reg MemRW;

//These opcode representation need to be followed for proper operation
parameter op_add=8'b001;
parameter op_or= 8'b010;
parameter op_jump=8'b011;
parameter op_jumpz=8'b100;
parameter op_load=8'b101;
parameter op_store=8'b110;

// Additional opcodes
parameter op_halt = 8'b000;
parameter op_sub = 8'b111;
parameter op_and = 8'h08;


// We move through the states at each clock cycle
//
// At Jumpz look at the zeroflag, if high, go to the exec jump state or go to fetch_1 state. 
//

//***** When at each of the state you will have to set all the appropriate outputs as shown in the finite
//state machine.

/* These are our state assignments, we need four bits to represent our 12 states (1-12) */
reg [4:0] CURRENT_STATE;
reg [4:0] NEXT_STATE;
parameter FETCH_1 		= 5'b00000; // 0  == Fetch_1
parameter FETCH_2 		= 5'b00001; // 1  == Fetch_2
parameter FETCH_3 		= 5'b00010; // 2  == Fetch_3
parameter DECODE 		= 5'b00011; // 3  == Decode
parameter EXECADD_1 	= 5'b00100;	// 4  == ExecADD_1
parameter EXECADD_2		= 5'b00101;	// 5  == ExecADD_2
parameter EXECOR_1		= 5'b00110;	// 6  == ExecOR_1
parameter EXECOR_2		= 5'b00111;	// 7  == ExecOR_2
parameter EXECLOAD_1	= 5'b01000;	// 8  == ExecLoad_1
parameter EXECLOAD_2	= 5'b01001;	// 9  == ExecLoad_2
parameter EXECSTORE_1	= 5'b01010;	// 10 == ExecStore_1
parameter EXECJUMP		= 5'b01011;	// 11 == ExecJump

// new additional states, for halt, subtract, AND
parameter HALT_STATE	= 5'b01100;	// 12 == Halt State
parameter EXECSUB_1     = 5'b01101; // 13 == Subtract_1
parameter EXECSUB_2     = 5'b01110; // 14 == Subtract_2 
parameter EXECAND_1		= 5'b01111;	// 15 == And_1
parameter EXECAND_2		= 5'b10000;	// 16 == And_2
parameter BUFFER_JUMP	= 5'b10001; // 17

always @(posedge clk) begin
// Within this block, we move between states

	if (rst)
		CURRENT_STATE = FETCH_1;
	else
		CURRENT_STATE = NEXT_STATE;
		
end 

always @(CURRENT_STATE or opcode or zflag) begin

	case (CURRENT_STATE)
			FETCH_1:
				NEXT_STATE = FETCH_2;
			FETCH_2:
				NEXT_STATE = FETCH_3;
			FETCH_3:
				NEXT_STATE = DECODE;
			DECODE: begin
			
			case (opcode)
				op_add:   begin NEXT_STATE = EXECADD_1;   end
				op_or:    begin NEXT_STATE = EXECOR_1;    end
				op_jump:  begin NEXT_STATE = EXECJUMP;    end
				op_jumpz: begin if (zflag) begin 
							NEXT_STATE = EXECJUMP; 
						  end else begin 
							NEXT_STATE = FETCH_1; 
						  end 
						  end
				op_load:  begin NEXT_STATE = EXECLOAD_1;  end
				op_store: begin NEXT_STATE = EXECSTORE_1; end
				op_halt:  begin NEXT_STATE = HALT_STATE;  end
				op_sub:   begin NEXT_STATE = EXECSUB_1;   end
				op_and:   begin NEXT_STATE = EXECAND_1;   end
				default:  begin NEXT_STATE = HALT_STATE;  end
			endcase  
			end 

			EXECADD_1:
				NEXT_STATE = EXECADD_2;
			EXECADD_2:
				NEXT_STATE = FETCH_1;
			EXECOR_1:
				NEXT_STATE = EXECOR_2;
			EXECOR_2:
				NEXT_STATE = FETCH_1;
			EXECLOAD_1:
				NEXT_STATE = EXECLOAD_2;
			EXECLOAD_2:
				NEXT_STATE = FETCH_1;
			EXECSTORE_1:
				NEXT_STATE = FETCH_1;
			EXECJUMP:
				NEXT_STATE = FETCH_1;
			HALT_STATE:
				NEXT_STATE = HALT_STATE;
			EXECSUB_1: 
				NEXT_STATE = EXECSUB_2;
			EXECSUB_2:
				NEXT_STATE = FETCH_1;
			EXECAND_1:
				NEXT_STATE = EXECAND_2;
			EXECAND_2:
				NEXT_STATE = FETCH_1;
			BUFFER_JUMP:
				NEXT_STATE = FETCH_1;
	endcase
	
end

	always @(CURRENT_STATE) begin
		
		muxPC = 0; 
		muxMAR = 0;
		muxACC = 0;
		loadMAR = 0;
		loadPC = 0;
		loadACC = 0;
		loadMDR = 0;
		loadIR = 0;
		opALU = 0;
		MemRW = 0;
		
		case (CURRENT_STATE)
		FETCH_1:     begin
				muxPC = 0; 
				muxMAR = 0;
				muxACC = 0;
				loadMAR = 1;
				loadPC = 1;
				loadACC = 0;
				loadMDR = 0;
				loadIR = 0;
				opALU = 0;
				MemRW = 0;
			    end

		FETCH_2:     begin
				muxPC = 0; 
				muxMAR = 0;
				muxACC = 0;
				loadMAR = 0;
				loadPC = 0;
				loadACC = 0;
				loadMDR = 1;
				loadIR = 0;
				opALU = 0;
				MemRW = 0;
			    end

		FETCH_3:     begin
				muxPC = 0; 
				muxMAR = 0;
				muxACC = 0;
				loadMAR = 0;
				loadPC = 0;
				loadACC = 0;
				loadMDR = 0;
				loadIR = 1;
				opALU = 0;
				MemRW = 0;
			    end

		DECODE:      begin
				muxPC = 0; 
				muxMAR = 1;
				muxACC = 0;
				loadMAR = 1;
				loadPC = 0;
				loadACC = 0;
				loadMDR = 0;
				loadIR = 0;
				opALU = 0;
				MemRW = 0;
			     end

		EXECADD_1:   begin
				muxPC = 0; 
				muxMAR = 0;
				muxACC = 0;
				loadMAR = 0;
				loadPC = 0;
				loadACC = 0;
				loadMDR = 1;
				loadIR = 0;
				opALU = 0;
				MemRW = 0;
			    end

		EXECADD_2:   begin
				muxPC = 0; 
				muxMAR = 0;
				muxACC = 0;
				loadMAR = 0;
				loadPC = 0;
				loadACC = 1;
				loadMDR = 0;
				loadIR = 0;
				opALU = 1;
				MemRW = 0;
			    end

		EXECOR_1:    begin
				muxPC = 0; 
				muxMAR = 0;
				muxACC = 0;
				loadMAR = 0;
				loadPC = 0;
				loadACC = 0;
				loadMDR = 1;
				loadIR = 0;
				opALU = 0;
				MemRW = 0;			
			    end

		EXECOR_2:    begin
				muxPC = 0; 
				muxMAR = 0;
				muxACC = 0;
				loadMAR = 0;
				loadPC = 0;
				loadACC = 1;
				loadMDR = 0;
				loadIR = 0;
				opALU = 0;
				MemRW = 0;			
			    end

		EXECLOAD_1:  begin
				muxPC = 0; 
				muxMAR = 0;
				muxACC = 0;
				loadMAR = 0;
				loadPC = 0;
				loadACC = 0;
				loadMDR = 1;
				loadIR = 0;
				opALU = 0;
				MemRW = 0;			
				end

		EXECLOAD_2:  begin
				muxPC = 0; 
				muxMAR = 0;
				muxACC = 1;
				loadMAR = 0;
				loadPC = 0;
				loadACC = 1;
				loadMDR = 0;
				loadIR = 0;
				opALU = 0;
				MemRW = 0;			
			    end

		EXECSTORE_1: begin
				muxPC = 0; 
				muxMAR = 0;
				muxACC = 0;
				loadMAR = 0;
				loadPC = 0;
				loadACC = 0;
				loadMDR = 0;
				loadIR = 0;
				opALU = 0;
				MemRW = 1;			
			    end

		EXECJUMP:    begin
				muxPC = 1; 
				muxMAR = 0;
				muxACC = 0;
				loadMAR = 0;
				loadPC = 1;
				loadACC = 0;
				loadMDR = 0;
				loadIR = 0;
				opALU = 0;
				MemRW = 0;			
			    end
		EXECSUB_1:   begin
				muxPC = 0; 
				muxMAR = 0;
				muxACC = 0;
				loadMAR = 0;
				loadPC = 0;
				loadACC = 0;
				loadMDR = 1;
				loadIR = 0;
				opALU = 0;
				MemRW = 0;
			    end

		EXECSUB_2:   begin
				muxPC = 0; 
				muxMAR = 0;
				muxACC = 0;
				loadMAR = 0;
				loadPC = 0;
				loadACC = 1;
				loadMDR = 0;
				loadIR = 0;
				opALU = 2;
				MemRW = 0;
			    end
		EXECAND_1:   begin
				muxPC = 0; 
				muxMAR = 0;
				muxACC = 0;
				loadMAR = 0;
				loadPC = 0;
				loadACC = 0;
				loadMDR = 1;
				loadIR = 0;
				opALU = 0;
				MemRW = 0;
			    end

		EXECAND_2:   begin
				muxPC = 0; 
				muxMAR = 0;
				muxACC = 0;
				loadMAR = 0;
				loadPC = 0;
				loadACC = 1;
				loadMDR = 0;
				loadIR = 0;
				opALU = 3;
				MemRW = 0;
			    end	
		BUFFER_JUMP: begin
				muxPC = 0; 
				muxMAR = 0;
				muxACC = 0;
				loadMAR = 0;
				loadPC = 1;
				loadACC = 0;
				loadMDR = 0;
				loadIR = 0;
				opALU = 0;
				MemRW = 0;
				end
	endcase
end 
endmodule 


// Register Bank
// ******************************
//           COMPLETE
// ******************************
module registers(
 clk,
 rst,
 PC_reg,
 PC_next,
 IR_reg,
 IR_next,
 ACC_reg,
 ACC_next,
 MDR_reg,
 MDR_next,
 MAR_reg,
 MAR_next,
 Zflag_reg,
 zflag_next
 );

input wire clk;
input wire rst;
output reg [7:0]PC_reg;
input wire [7:0]PC_next;

output reg [15:0]IR_reg;
input wire [15:0]IR_next;
output reg [15:0]ACC_reg;
input wire [15:0]ACC_next;
output reg [15:0]MDR_reg;
input wire [15:0]MDR_next;
output reg [7:0]MAR_reg;
input wire [7:0]MAR_next;
output reg Zflag_reg;
input wire zflag_next;

always @(posedge clk or posedge rst) begin
if (rst) begin
	PC_reg <= 0;
	IR_reg <= 0;
	ACC_reg <= 0;
	MDR_reg <= 0;
	MAR_reg <= 0;
	Zflag_reg <= 0;
end else begin
	PC_reg <= PC_next;
	IR_reg <= IR_next;
	ACC_reg <= ACC_next;
	MDR_reg <= MDR_next;
	MAR_reg <= MAR_next;
	Zflag_reg <= zflag_next;
end

end


//This is a very simple module. At reset set all registers to zero. At all other clocks cycles, All it
//does is at each rising edge of clock, it grabs the next value and stores it in the registers. 

endmodule 


// Data path: In this module the next values are generated for all the registers and the singles to
// drive all the muxes.
module datapath(
 clk,
 rst,
 muxPC,
 muxMAR,
 muxACC,
 loadMAR,
 loadPC,
 loadACC,
 loadMDR,
 loadIR,
 opALU,
 zflag,
 opcode,
 MemAddr,
 MemD,
 MemQ
 ); 

 input clk;
 input rst;
 input muxPC;
 input muxMAR;
 input muxACC;
 input loadMAR;
 input loadPC;
 input loadACC;
 input loadMDR;
 input loadIR;
 input [1:0]opALU;
 output zflag;
 output [7:0]opcode;
 output reg [7:0]MemAddr;
 output [15:0]MemD;
 input [15:0]MemQ;

reg [7:0]PC_next;
//wire [15:0]IR_next;
reg [15:0]IR_next;
reg [15:0]ACC_next;
//wire [15:0]MDR_next;
reg [15:0]MDR_next;
reg [7:0]MAR_next;
wire [7:0]PC_reg;
wire [15:0]IR_reg;
wire [15:0]ACC_reg;
wire [15:0]MDR_reg;
wire [7:0]MAR_reg;
reg zflag;
wire [15:0]ALU_out;

//one instance of ALU
alu alus(ACC_reg, MDR_reg, opALU, ALU_out);


//one instance of register. 
	registers regs(	clk, rst, PC_reg, PC_next, IR_reg, IR_next,
 			ACC_reg, ACC_next, MDR_reg, MDR_next, MAR_reg,
			MAR_next, Zflag_reg, zflag_next);

//code to generate

always @(*) begin

	if (loadPC) begin
		if (muxPC) begin
			PC_next = IR_reg[15:8] ;
		end else begin
			PC_next = PC_reg + 1'b1;
		end
	end else begin
		PC_next = PC_reg;
	end
	
	if (loadIR) begin
		IR_next = MDR_reg;	
	end else begin
		IR_next = IR_reg;
	end
	
	if (loadACC) begin
		if (muxACC) begin
			ACC_next = MDR_reg;
		end else begin
			ACC_next = ALU_out;
		end	
	end else begin
		ACC_next = ACC_reg;
	end
	
	if (loadMDR) begin
		MDR_next = MemQ;
	end else begin
		MDR_next = MDR_reg;
	end
	
	if (loadMAR) begin
		if (muxMAR) begin
			MAR_next = IR_reg[15:8];
		end else begin
			MAR_next = PC_reg;
		end
	end else begin
		MAR_next = MAR_reg;
	end
	
	zflag = (!ACC_reg)? 1:0;
	
	MemAddr = MAR_next;
	
end

assign opcode = IR_reg[7:0];
assign MemD = ACC_reg;

endmodule 