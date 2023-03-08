`timescale 1ns / 1ps

module reversePolishNotation
(
   input  clk,
   input  rst,
   input  dIn,
   output dOut,
	output reg overflow, 
	output reg underflow
);
	reg overflowNext = 1;
	reg underflowNext = 1;
	reg wEn;
	reg [7:0] LIFO_dIn;
	reg rEn;

	wire full;
	wire empty;
	wire [7:0] LIFO_dOut;
	reg dInPrev, dInPrev2;
	reg [3:0] cnt, cntNext;
	reg [7:0] row, rowNext, rowPrev;
	
	reg [3:0] st, stNext;
	reg [7:0] streamIn;
	reg streamEn;
	
	reg LIFO_rst;
	LIFO #(8, 4)lifo (
		.clk(clk), 
		.rst(LIFO_rst), 
		.full(full), 
		.wEn(wEn), 
		.dIn(LIFO_dIn), 
		.empty(empty), 
		.rEn(rEn), 
		.dOut(LIFO_dOut)
	);
	StreamingOut streamer (
		.clk(clk), 
		.rst(rst), 
		.inEn(streamEn), 
		.dIn(streamIn), 
		.dOut(dOut));
	
	always@(posedge clk) begin
		dInPrev	 <= #1 dIn;
		dInPrev2	 <= #1 dInPrev;
		st			 <= #1 stNext;
		row		 <= #1 rowNext;
		rowPrev   <= #1 row;
		cnt		 <= #1 cntNext;
		overflow  <= #1 overflowNext;
		underflow <= #1 underflowNext;
	end
	reg [1:0] operand;
	always@*begin
		overflowNext = overflow;
		underflowNext = underflow;
		
		stNext = st;
		LIFO_rst = 0;
		rEn = 0;
		wEn = 0;
		cntNext = cnt;
		rowNext = row;
		streamEn = 0;
		streamIn = 0;
		operand = 0;
		LIFO_dIn = 0;
		if(rst) begin
			overflowNext = 0;
			underflowNext = 0;
			stNext = 0;
			cntNext = 0;
			rowNext = 0;
			LIFO_rst = 1;
		end else begin
			case(st)
				0:begin //recieved 1st bit
					if(dIn)
						stNext = 1;
				end
				1:begin //operand or number
					if(dIn ==0)
						stNext = 2;
					else
						stNext = 3;
				end
				2:begin	//number
					if(cnt < 8) begin
						cntNext = cnt +1;
						rowNext = {row, dIn};
					end else begin //all bits recieved, write to LIFO
						cntNext = 0;
						stNext = 0;	
						LIFO_dIn = row;
						rowNext = 0;						
						if(full)
							overflowNext =  1;
						else begin
							wEn = 1;
						end
					end
				end
				3:begin	//operand
					stNext = 4;
				end
				4:begin //to use data from registers (stable)
					stNext = 5;
				end
				5:begin	//execute operand or start streaming
					operand = {dInPrev2, dInPrev};
					case(operand)
						0:begin //rst
							LIFO_rst = 1;
							stNext = 0;
						end
						1:begin //add
							stNext = 6;
							rowNext = LIFO_dOut;
							if(empty)
								underflowNext = 1;
							else 
								rEn = 1;
						end
						
						2:begin //mult
							stNext = 8;
							rowNext = LIFO_dOut;
							if(empty)
								underflowNext = 1;
							else 
								rEn = 1;
						end
						3:begin //stream output
							stNext = 0;
							streamIn = LIFO_dOut;
							streamEn = 1;	
						end
					endcase
				end
				6:begin //read 2nd operand and store in register
					stNext = 7;
					rowNext = LIFO_dOut;
					if(empty)
						underflowNext = 1;
					else
						rEn = 1;
				end
				7:begin //execute operation and write to LIFO
					LIFO_dIn = row + rowPrev;
					rEn = 0;
					stNext = 0;
					rowNext = 0;
					if(full)
						overflowNext =  1;
					else 
						wEn = 1;
				end			
				8:begin//read 2nd operand and store in register
					stNext = 9;
					rowNext = LIFO_dOut;
					if(empty)
						underflowNext = 1;
					else 
						rEn = 1;
				end
				9:begin //execute operation and write to LIFO
					LIFO_dIn = row * rowPrev;
					rEn = 0;
					stNext = 0;
					rowNext = 0;
					if(full)
						overflowNext =  1;
					else begin
						wEn = 1;
					end
				end
			endcase
		end
	end
endmodule
