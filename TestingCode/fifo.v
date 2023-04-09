`timescale 1ns / 1ps
module SyncFIFO(clk, rst, full, wEn, dIn, empty, rEn, dOut, faultEn);
parameter BITWIDTH = 5;
parameter DEPTH = 4;
input clk;
input rst;
input wEn;
input rEn;
input faultEn;
input [BITWIDTH-1:0] dIn;
output full;
output empty;
output reg [BITWIDTH-1:0] dOut;
reg [BITWIDTH-1:0] vars    [0:2**(DEPTH)-1];
reg [BITWIDTH-1:0] varsNxt [0:2**(DEPTH)-1]; //to avoid latches
integer ii;
reg [DEPTH:0] rPtr;
reg [DEPTH:0] rPtrNxt;
reg [DEPTH:0] wPtr;
reg [DEPTH:0] wPtrNxt;
reg [DEPTH:0] wPtrPrev; //the extra bit is used as a flag to differentiate between full and empty
always@(posedge clk)begin
	rPtr 		<= #1 rPtrNxt;
	wPtr 		<= #1 wPtrNxt;
	wPtrPrev <= #1 wPtr;
	for (ii = 0; ii < 2**(DEPTH); ii = ii+1) begin //to avoid latches
		vars[ii] <= #1 varsNxt[ii];
	end
end

always@* begin
	for (ii = 0; ii < 2**(DEPTH); ii = ii+1) begin //to avoid latches
		varsNxt[ii] = vars[ii];
	end
	dOut = vars[rPtr[DEPTH-1:0]][BITWIDTH-1:0];
	rPtrNxt  = rPtr;
	wPtrNxt  = wPtr;
	if(rst) begin
		rPtrNxt = 0;
		wPtrNxt = 0;
		dOut 	  = 0;
		for (ii = 0; ii < 2**(DEPTH); ii = ii+1) begin
			varsNxt[ii] = 0;
		end
	end else begin		
		//normal read
		if(!empty &rEn)begin 
			rPtrNxt = rPtr + 1;
		end
		//normal write, if (empty & rEn & wEn) we can output dIn directly, no need to write in the memory
		// if its full but both rEn and wEn are 1, we can read and write
		if(!full & wEn &!(empty & rEn & wEn) | (full & rEn & wEn)) begin 
			varsNxt[wPtr[DEPTH-1:0]] = dIn;
			wPtrNxt = wPtr + 1;
		end		
		//if it's empty but both rEn and wEn are 1, we can output dIn, no need to write in memory
		if(empty & rEn & wEn) begin 
			dOut = dIn;
		end
	end
end

assign empty =  (wPtr == rPtr) ? 1'b1: 1'b0;
assign full  =  ((wPtr[DEPTH-1:0] == rPtr[DEPTH-1:0]) & (wPtr[DEPTH] != rPtr[DEPTH]))   ? 1'b1: 1'b0;

endmodule 
