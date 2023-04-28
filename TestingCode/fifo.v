`timescale 1ns / 1ps
module SyncFIFO(clk, rst, full, wEn, dIn, empty, rEn, dOut, faultEn);
parameter BITWIDTH = 5;
parameter DEPTH = 4;
input clk;
input rst;
input wEn;
input rEn;
input faultEn;
input [5-1:0] dIn;
output full;
output empty;
output reg [5-1:0] dOut;
reg [5-1:0] vars    [0:2**(4)-1];
reg [5-1:0] varsNxt [0:2**(4)-1]; //to avoid latches
integer ii;
reg [4:0] rPtr;
reg [4:0] rPtrNxt;
reg [4:0] wPtr;
reg [4:0] wPtrNxt;
reg [4:0] wPtrPrev; //the extra bit is used as a flag to differentiate between full and empty
always@(posedge clk)begin
	rPtr 		<= #1 rPtrNxt;
	wPtr 		<= #1 wPtrNxt;
	wPtrPrev <= #1 wPtr;
	for (ii = 0; ii < 2**(4); ii = ii+1) begin //to avoid latches
		vars[ii] <= #1 varsNxt[ii];
	end
end

always@* begin
	for (ii = 0; ii < 2**(4); ii = ii+1) begin //to avoid latches
		varsNxt[ii] = vars[ii];
	end
	dOut = vars[rPtr[4-1:0]][5-1:0];
	rPtrNxt  = rPtr;
	wPtrNxt  = wPtr;
	if(rst) begin
		rPtrNxt = 0;
		wPtrNxt = 0;
		dOut 	  = 0;
		for (ii = 0; ii < 2**(4); ii = ii+1) begin
			varsNxt[ii] = 0;
		end
	end else begin		

		if(!empty &rEn)begin 
			rPtrNxt = rPtr + 1;
		end

		if(!full & wEn &!(empty & rEn & wEn) | (full & rEn & wEn)) begin 
			varsNxt[wPtr[4-1:0]] = dIn;
			wPtrNxt = wPtr + 1;
		end		

		if(empty & rEn & wEn) begin 
			dOut = dIn;
		end
	end
end

assign empty =  (wPtr == rPtr) ? 1'b1: 1'b0;
assign full  =  ((wPtr[4-1:0] == rPtr[4-1:0]) & (wPtr[4] != rPtr[4]))   ? 1'b1: 1'b0;

endmodule 
