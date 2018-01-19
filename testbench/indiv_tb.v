// Output Tests for Project 1

module ALUTEST; 

reg [15:0] A;
reg [15:0] B;
reg opALU;
wire [15:0] Rout;

	alu benis(A, B, opALU, Rout);

initial begin
	A = 16'h0000;
	B = 16'h0001;
	opALU = 1;

 	#10 $display ("A = %b B = %b opALU = %b || Rout = %b", A, B, opALU, Rout);
	A = 16'hFFFF;
	opALU = 0;
 	#10 $display ("A = %b B = %b opALU = %b || Rout = %b", A, B, opALU, Rout);

end

endmodule 


module CTRTEST;

reg clk, rst, zflag;
reg [7:0] opcode;
wire muxPC, muxMAR, muxACC, loadMAR, loadPC, loadACC, loadMDR, loadIR, opALU, MemRW;

	ctr test(clk, rst, zflag, opcode, muxPC, muxMAR, muxACC, loadMAR, loadPC, loadACC, loadMDR, loadIR, opALU, MemRW);
	
always begin
	#5 clk = !clk;
end
	
initial begin
	clk = 0;
	rst = 1;
	opcode = 8'b010;
	
	#10 rst = 0;
end
	
endmodule 


module RAMTEST;
reg we;
reg [15:0]  d;
wire [15:0] q;
reg [7:0] addr;

	ram ram_ins(we, d, q, addr);

initial begin
$readmemh("memory.list", ram_ins.mem256x16);

	#10 we = 1;
		addr = 8'hc;
		d = 16'hf;
	#10 we = 0;
	#10 $display ("Q = %h", q);

#435
$display("ADDR 0000: %h\n",ram_ins.mem256x16[16'h0000]);
$display("ADDR 0001: %h\n",ram_ins.mem256x16[16'h0001]);
$display("ADDR 0002: %h\n",ram_ins.mem256x16[16'h0002]);
$display("ADDR 0003: %h\n",ram_ins.mem256x16[16'h0003]);
$display("ADDR 0004: %h\n",ram_ins.mem256x16[16'h0004]);
$display("ADDR 0005: %h\n",ram_ins.mem256x16[16'h0005]);
$display("ADDR 0006: %h\n",ram_ins.mem256x16[16'h0006]);
$display("ADDR 0007: %h\n",ram_ins.mem256x16[16'h0007]);
$display("ADDR 0008: %h\n",ram_ins.mem256x16[16'h0008]);
$display("ADDR 0009: %h\n",ram_ins.mem256x16[16'h0009]);
$display("ADDR 000a: %h\n",ram_ins.mem256x16[16'h000a]);
$display("ADDR 000b: %h\n",ram_ins.mem256x16[16'h000b]);
$display("ADDR 000c: %h\n",ram_ins.mem256x16[16'h000c]);
$display("ADDR 000d: %h\n",ram_ins.mem256x16[16'h000d]);
$display("ADDR 000e: %h\n",ram_ins.mem256x16[16'h000e]);
$finish;
end

endmodule

module CPUTEST;
reg clk, rst;
wire MemRW_IO;
wire [7:0]MemAddr_IO;
wire [15:0]MemD_IO;

	proj1 dut(clk, rst, MemRW_IO, MemAddr_IO, MemD_IO);

always
 #5 clk = !clk;

initial begin
$monitor("ADDR 0002: %d \n",$time,CPUTEST.dut.ram_ins.mem256x16[16'h0002]);
clk=1'b0;
rst=1'b1;
$readmemh("memory_copy.list", CPUTEST.dut.ram_ins.mem256x16);
#20 rst=1'b0;
#10000
/*$display("Final value\n");
$display("0x00d %d\n",CPUTEST.dut.ram_ins.mem256x16[16'h000d]);

$display("ADDR 0000: %h",CPUTEST.dut.ram_ins.mem256x16[16'h0000]);
$display("ADDR 0001: %h",CPUTEST.dut.ram_ins.mem256x16[16'h0001]);
$display("ADDR 0002: %h",CPUTEST.dut.ram_ins.mem256x16[16'h0002]);
$display("ADDR 0003: %h",CPUTEST.dut.ram_ins.mem256x16[16'h0003]);
$display("ADDR 0004: %h",CPUTEST.dut.ram_ins.mem256x16[16'h0004]);
$display("ADDR 0005: %h",CPUTEST.dut.ram_ins.mem256x16[16'h0005]);
$display("ADDR 0006: %h",CPUTEST.dut.ram_ins.mem256x16[16'h0006]);
$display("ADDR 0007: %h",CPUTEST.dut.ram_ins.mem256x16[16'h0007]);
$display("ADDR 0008: %h",CPUTEST.dut.ram_ins.mem256x16[16'h0008]);
$display("ADDR 0009: %h",CPUTEST.dut.ram_ins.mem256x16[16'h0009]);
$display("ADDR 000a: %h",CPUTEST.dut.ram_ins.mem256x16[16'h000a]);
$display("ADDR 000b: %h",CPUTEST.dut.ram_ins.mem256x16[16'h000b]);
$display("ADDR 000c: %h",CPUTEST.dut.ram_ins.mem256x16[16'h000c]);
$display("ADDR 000d: %h",CPUTEST.dut.ram_ins.mem256x16[16'h000d]);
$display("ADDR 000e: %h",CPUTEST.dut.ram_ins.mem256x16[16'h000e]);*/
$finish;
end
endmodule 