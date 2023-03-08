/*******************************************
Designer : Ahmet Kakacak
Module   : TB for Reverse Polish Notation
*******************************************/

`timescale 1ns/1ps

module tb_reversePolishNotation;

// gap between commands
parameter GAP = 10;

reg  clk = 1;
reg  rst = 1;
reg  dIn = 0;
wire dOut;

reg  [7:0] data8 = 0;
reg  [7:0] refData[0:7];
reg  [7:0] dataCaptured;

integer errorCnt = 0;
integer checkCnt = 0;

wire overflow, underflow;
// dut
reversePolishNotation dut(.clk(clk), .rst(rst), .dIn(dIn), .dOut(dOut), .overflow(overflow), .underflow(underflow));

// input
initial begin : feed_input
   repeat(10) @(posedge clk);
   rst = 0;
   repeat(10) @(posedge clk);
   repeat(5) begin
      data8 = data8 + 1;
      push(data8);
   end //1,2,3,4,5
   enter();//5
   add();//1,2,3,9
   enter();//9
   mult();//1,2,27
   enter();//27
   clear();//--
   data8 = 6;
   repeat(8) begin
      push(data8);
      data8 = data8 + 2;
   end //6,8,10,12,14,16,18,20
   repeat(4) add();// 6,8,10,80
   enter();//80
   push(8'd2);//6,8,10,80,2
   mult();//6,8,10,160
   enter();//160
   push(8'd0);//6,8,160,0
   mult();//6,8,0
   enter();//0
   push(8'd254);//6,8,0,254
   push(8'd1);//6,8,0,254,1
   add();//6,8,0,255
   enter();//255
   clear();//-
   push(8'd7);//7
   push(8'd9);//7,9
   push(8'd2);//7,9,2
   repeat(2) mult();//126
   enter();//126
   repeat(100) @(posedge clk); // depending on the size of the LIFO
   if(checkCnt!==8)
      $display("!!! ERROR !!! Simulation finished at time=%0d -> missed or redundant output, must be 8 checks", $time);
   else if(errorCnt==0)
      $display("*** SUCCESS *** Simulation finished at time=%0d -> no error", $time);
   else
      $display("!!! ERROR !!! Simulation finished at time=%0d -> %d error(s)", $time, errorCnt);
   data8 = 6;
   repeat(100) begin
      push(data8);
      data8 = data8;
   end
	if(!overflow)
		$display("overflow error");
	clear();
	repeat(10) begin
      add();
   end
	if(!underflow)
		$display("underflow error");
	$stop;
end

// output check
initial begin : check_output
   integer ii;
   integer jj;
   ii = 0;
   forever begin
      wait(dOut);
      @(posedge clk);
      @(negedge clk);
      if(dOut) begin
         errorCnt = errorCnt + 1;
         $display("ERROR!!! at time=%0d -> Unknown output protocol", $time);
      end
      for(jj=0; jj<8; jj=jj+1) begin
         @(negedge clk);
         dataCaptured[7-jj] = dOut;
      end
      @(posedge clk);
      if(dataCaptured==refData[ii]) begin
         checkCnt = checkCnt + 1;
         //$display("SUCCESS: at time=%0d -> Output=%d, Reference=%d", $time, dataCaptured, refData[ii]);
      end else begin
         checkCnt = checkCnt + 1;
         errorCnt = errorCnt + 1;
         $display("ERROR!!! at time=%0d -> Output=%d, Reference=%d", $time, dataCaptured, refData[ii]);
      end
      ii = ii + 1;
      @(posedge clk);
      repeat(GAP) @(posedge clk);
   end
end

// push data
task push;
   input [7:0] data;
   integer ii;
   begin
      @(posedge clk);
      dIn = 1;
      @(posedge clk);
      dIn = 0;
      for(ii=0; ii<8; ii=ii+1) begin
         @(posedge clk);
         dIn = data[7-ii];
      end
      @(posedge clk);
      dIn = 0;
      repeat(GAP) @(posedge clk);
   end
endtask

// clear
task clear;
   begin
      @(posedge clk);
      dIn = 1;
      repeat(2) @(posedge clk);
      dIn = 0;
      repeat(2) @(posedge clk);
      repeat(GAP) @(posedge clk);
   end
endtask

// add
task add;
   begin
      @(posedge clk);
      dIn = 1;
      repeat(2) @(posedge clk);
      dIn = 0;
      @(posedge clk);
      dIn = 1;
      @(posedge clk);
      dIn = 0;
      repeat(GAP) @(posedge clk);
   end
endtask

// multiply
task mult;
   begin
      @(posedge clk);
      dIn = 1;
      repeat(3) @(posedge clk);
      dIn = 0;
      @(posedge clk);
      repeat(GAP) @(posedge clk);
   end
endtask

// pop latest data
task enter; //check
   begin
      @(posedge clk);
      dIn = 1;
      repeat(4) @(posedge clk);
      dIn = 0;
      repeat(10) @(posedge clk);
      repeat(GAP) @(posedge clk);
   end
endtask

// reference output
initial begin
   refData[0] = 5;
   refData[1] = 9;
   refData[2] = 27;
   refData[3] = 80;
   refData[4] = 160;
   refData[5] = 0;
   refData[6] = 255;
   refData[7] = 126;
end

// clock
always #5 clk = !clk;

endmodule


/******************************************/
