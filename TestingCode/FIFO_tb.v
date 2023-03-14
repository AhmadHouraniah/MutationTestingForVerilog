`timescale 1ns / 1ps
`define BITWIDTH 6
`define DEPTH 4
`define NUMREADS 500
module FIFO_tb;

   reg clk, rst;
   
   initial begin
      clk = 0;
      forever
        #5 clk = ~clk;
   end

   initial begin
      $dumpfile("FIFO.vcd");
      $dumpvars(2, FIFO_tb);
      rst <= #1 1;
      repeat(2) @(posedge clk);
      rst <= #1 0;
   end

   // Control simulation termination from a single command center:
   initial begin
      fork
         forever begin
            @(checker.numRead);
            if(checker.numRead%100 == 0)
	      $display("numRead = ", checker.numRead);
            if(checker.numRead == `NUMREADS) begin
               @(posedge clk);
               if(checker.errorCnt == 0)
                 $display("pass ======> No errors. Congrats!");
               $finish;
            end
         end
         forever begin
            @(checker.errorCnt);
            if(checker.errorCnt == 5) begin
               $display("fail ======> Stopped after 5 errors!");
               $finish;
	    end
         end
      join
   end

   wire [`BITWIDTH-1:0] dIn, dOut;
   
   // note that we can always read
   // and rEn=1 in fact indicates pop
   // rather than read.
   SyncFIFO #(`BITWIDTH, `DEPTH) DUT(.clk(clk), .rst(rst),
                             .full(full), .wEn(wEn), .dIn(dIn),
                             .empty(empty), .rEn(rEn), .dOut(dOut));

   driver driver(.clk(clk), .rst(rst),
                 .full(full), .wEn(wEn), .dIn(dIn),
                 .rEn(rEn));
   
   checker checker(.clk(clk), .rst(rst),
                   .empty(empty), .rEn(rEn), .dOut(dOut), .wEn(wEn));

endmodule // oneSlotFIFO_tb

module driver(clk, rst, full, wEn, dIn, rEn);
   input clk, rst;
   input full;
   output wEn;
   output [`BITWIDTH-1:0] dIn;
   input                  rEn;

   reg                    wEn;
   reg [`BITWIDTH-1:0]    dIn;

   integer                waitLen, burstLen;
   reg [3:0]              len;

   initial begin
      dIn = 0;
      wEn = 0;
      @(negedge rst);

      forever begin
         len = $random;
         repeat(len) @(posedge clk);

         len = $random%(2**`DEPTH);
         burstWriteIfYouCan(len);
      end
   end
   
   task burstWriteIfYouCan;
      input [3:0]         burstWrLen;
      begin
         repeat(burstWrLen) begin
            // check for the corner case of wEn=1 when full=1 but rEn=1
            wait(~full | rEn);

            wEn = 1;
            @(posedge clk);
            wEn <= #1 0;
            dIn <= #1 (dIn +1)%(1<<`BITWIDTH);

            // wait for full signal to react
            @(negedge clk);
         end
      end
   endtask // burstWriteIfYouCan

endmodule // driver

module checker(clk, rst, empty, rEn, dOut, wEn);
   input clk, rst;
   input empty, wEn;
   output rEn;
   input [`BITWIDTH-1:0] dOut;

   reg                    rEn;
   reg [`BITWIDTH-1:0]    dOutRef;

   reg [3:0]              len;

   initial begin
      dOutRef = 0;
      rEn = 0;
      @(negedge rst);
      forever begin
         len = $random;
         repeat(len) @(posedge clk);

         len = $random;
         burstReadIfYouCan(len);
      end
   end

   integer numRead=0, errorCnt=0;

   task burstReadIfYouCan;
      input [3:0] burstRdLen;
      begin
         repeat(burstRdLen) begin
				//check for the corner case when empty = 1, wEn = 1, and rEn = 1, it should output dIn
            wait(~empty | wEn);
            numRead <= #1 numRead +1;                                   
            rEn = 1;
            #2; // wait just in case dOut changes too early
            
            if(dOut !== dOutRef) begin
               $display("======> Error at time=%0d: dOut=%d vs dOutRef=%d",
                        $time, dOut, dOutRef);
               errorCnt = errorCnt +1;
            end

            @(posedge clk);
            rEn <= #1 0;
            dOutRef <= #1 (dOutRef +1)%(1<<`BITWIDTH);

            // wait for empty signal to react
            @(negedge clk);
         end
      end
   endtask

endmodule // checker
