`timescale 1ns / 1ps
module SyncFIFO(clk, rst, full, wEn, dIn, empty, rEn, dOut, faultEn);
parameter BITWIDTH = 5;
parameter DEPTH = 4;
input clk, rst, wEn, rEn, faultEn;
wire wEn1 =  wEn;
input [5-1:0] dIn;
output full, empty;
output reg [5-1:0] dOut;
reg [5-1:0] vars    [0:2**(4)-1];
reg [5-1:0] varsNxt [0:2**(4)-1]; //to avoid latches
integer ii;
reg [4:0] rPtr, rPtrNxt, wPtr, wPtrNxt, wPtrPrev; //the extra bit is used as a flag to differentiate between full and empty
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
		//normal read
		if(!empty &rEn)begin 
			rPtrNxt = rPtr + 1;
		end
		//normal write, if (empty & rEn & wEn) we can output dIn directly, no need to write in the memory
		// if its full but both rEn and wEn are 1, we can read and write
		if(!full & wEn1 &!(empty & rEn & wEn1) | (full & rEn & wEn1)) begin 
			varsNxt[wPtr[4-1:0]] = dIn;
			wPtrNxt = wPtr + 1;
		end		
		//if it's empty but both rEn and wEn are 1, we can output dIn, no need to write in memory
		if(empty & rEn & wEn1) begin 
			dOut = dIn;
		end
	end
end

assign empty =  (wPtr == rPtr) ? 1'b1: 1'b0;
assign full  =  ((wPtr[4-1:0] == rPtr[4-1:0]) & (wPtr[4] != rPtr[4]))   ? 1'b1: 1'b0;

endmodule 
