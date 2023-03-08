module LIFO(clk, rst, full, wEn, dIn, empty, rEn, dOut);
parameter BITWIDTH = 5;
parameter DEPTH = 4;
input clk, rst, wEn, rEn;
input [BITWIDTH-1:0] dIn;
output full, empty;
output reg [BITWIDTH-1-1:0] dOut;
reg [BITWIDTH-1:0] vars    [0:2**(DEPTH)-1];
reg [BITWIDTH-1:0] varsNxt [0:2**(DEPTH)-1]; //to avoid latches
integer ii;
reg [DEPTH:0] ptr, ptrNxt; //the extra bit is used as a flag to differentiate between full and empty
always@(posedge clk)begin
	ptr 		<= #1 ptrNxt;
	for (ii = 0; ii < 2**(DEPTH); ii = ii+1) begin //to avoid latches
		vars[ii] <= #1 varsNxt[ii];
	end
end

always@* begin
	for (ii = 0; ii < 2**(DEPTH); ii = ii+1) begin //to avoid latches
		varsNxt[ii] = vars[ii];
	end
	dOut = vars[ptr[DEPTH-1:0]-1];
	ptrNxt  = ptr;
	if(rst) begin
		ptrNxt = 0;
		dOut 	  = 0;
		for (ii = 0; ii < 2**(DEPTH); ii = ii+1) begin
			varsNxt[ii] = 0;
		end
	end else begin		
		if(rEn & wEn) begin
			varsNxt[ptr[DEPTH-1:0]] = dIn;
		end else begin
			if(rEn)begin 
				ptrNxt = ptr - 1;
			end
			if(wEn) begin 
				varsNxt[ptr[DEPTH-1:0]] = dIn;
				ptrNxt = ptr + 1;
			end		
		end
	end
end

assign empty = (ptr == 0);
assign full  = ((ptr[DEPTH-1:0] == 0) & (ptr[DEPTH] == 1));

endmodule 