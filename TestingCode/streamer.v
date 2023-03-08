`timescale 1ns / 1ps

module StreamingOut(clk, rst, dIn, dOut, inEn
    );
input clk, rst, inEn;
input [7:0] dIn;
output reg dOut;
reg [8:0] data, dataNext;
reg [3:0] cnt, cntNext;
reg start, startNext;
always@(posedge clk) begin
	data <= #1 dataNext;
	cnt  <= #1 cntNext;
	start<= #1 startNext;
end

always@*begin
	startNext = start;
	dOut = 0;
	dataNext = data;
	cntNext = cnt;
	if(rst) begin
		dataNext = 0;
		cntNext = 0;
		startNext = 0;
	end else begin
		if(inEn) begin
			dataNext = {1'b0, dIn[7:0]};
			dOut = 1;
			cntNext = 8;
			startNext = 1;
		end else if(start & cnt>0) begin
			cntNext = cnt-1;
			dOut = data[cnt];
		end else if(start) begin
			dOut = data[0];
			cntNext = 8;
			startNext = 0;
		end
	end
end

endmodule
