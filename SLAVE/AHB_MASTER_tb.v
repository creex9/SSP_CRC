module AHB_MASTER_tb ;

	//INPUTs REGs
	 reg 							HCLK;
	 reg 							RESET;
	 reg				[16-1:0]	HRDATA;
	 reg							HREADY;
	 reg							HRESP;
	 reg							REGs_ready;
	 reg 				[16-1:0]	DADR;	
	 reg 				[16-1:0]	CADR;
	 reg 				[1:0]		DLEN;
	 reg 							isSumReady;
	 reg 				[16-1:0]	SUM1;
	 reg 				[16-1:0]	SUM2;
	 reg 				[16-1:0]	SUM3;
	 reg 				[16-1:0]	SUM4;
	 reg 				[16-1:0]	SUM5;
	 reg 				[16-1:0]	SUM6;
	 reg 				[16-1:0]	SUM7;
	 reg 				[16-1:0]	SUM8;




	//OUTPUTs



	 AHB_MASTER #(.DATA_WIDTH(16), .ADDR_WIDTH(16) ) U0 (
	 	.HCLK 			(HCLK),
	 	.RESET 			(RESET),
	 	.REGs_ready 	(REGs_ready),
	 	.DADR 			(DADR),
	 	.CADR 			(CADR),
	 	.DLEN 			(DLEN),
	 	.isSumReady		(isSumReady),
	 	.SUM1 			(SUM1),
	 	.SUM2 			(SUM2),
	 	.SUM3 			(SUM3),
	 	.SUM4 			(SUM4),
	 	.SUM5 			(SUM5),
	 	.SUM6 			(SUM6),
	 	.SUM7 			(SUM7),
	 	.SUM8 			(SUM8)
	 	);







	 initial begin
	 #1 HCLK = 0;
	 #2 RESET = 1 ;
	 #2 RESET = 0 ;
	  	#10 RESET = 1;
 

	 #3 REGs_ready = 0;
	 isSumReady = 0;
	  	SUM1 = 12;
	 	SUM2= 3;
	 	SUM3 = 4;
	 	SUM4 = 2;
	 	SUM5 = 8;
	 	SUM6 = 1;
	 	SUM7 =3;
	 	SUM8 = 10;
	 #2	isSumReady = 1;
	 #2 DADR = 16'd1;
	 	DLEN = 2'b00;
	 	CADR = 16'd20;
	 #2 REGs_ready = 1;

	 #5REGs_ready = 0;
	 isSumReady = 0;
	 




	 #30
	  	SUM1 = 15;
	 	SUM2= 9;
	 	SUM3 = 89;
	 	SUM4 = 78;
	 	SUM5 = 67;
	 	SUM6 = 56;
	 	SUM7 =45;
	 	SUM8 = 34;
	 #2	isSumReady = 1;
	 #2 DADR = 16'd1;
	 	DLEN = 2'b01;
	 	CADR = 16'd10;
	 #1 REGs_ready = 1;
	 #2 REGs_ready = 0;	

	#30
	#2	isSumReady = 0;
	#2 	DADR = 16'd10;
	 	DLEN = 2'b01;
	 	CADR = 16'd10;
	 	#2 REGs_ready = 1;



		end

	always  
	
	#1 HCLK = !HCLK;



	initial begin
		$dumpfile ("AHB_MAST.vcd");
		$dumpvars;
	end
	

	initial begin
		
 	#300 $finish;
 	end





endmodule
