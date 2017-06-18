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
	 wire 				[16-1:0]	HADDR;
	 wire 				[16-1:0]	HWDATA;
	 wire 				[2:0]		HBURST;
	 wire 				[2:0]		HSIZE;
	 wire				[1:0] 		HTRANS;
	 wire 							HWRITE;
	 wire 							HMASTLOCK;


	 AHB_MASTER #(.DATA_WIDTH(16), .ADDR_WIDTH(16) ) U0 (
	 	.HCLK 			(HCLK),
	 	.RESET 			(RESET),
	 	.HRDATA 		(HRDATA),
	 	.HREADY 		(HREADY),
	 	.HRESP 			(HRESP),
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
	 	.SUM8 			(SUM8),
	 	.HADDR 			(HADDR),
	 	.HWDATA 		(HWDATA),
	 	.HBURST 		(HBURST),
	 	.HSIZE 			(HSIZE),
	 	.HTRANS 		(HTRANS),
	 	.HWRITE 		(HWRITE),
	 	.HMASTLOCK 		(HMASTLOCK)
	 	);







	 initial begin
	 #1 HCLK = 0;
	 #2 RESET = 1 ;
	 #2 RESET = 0 ;
	  #2 HREADY = 1; 
	 #3 REGs_ready = 0;
	 isSumReady = 0;
	 #2 DADR = 16'd1;
	 	DLEN = 2'b01;
	 	CADR = 16'd20;
	 #5 REGs_ready = 1;
	 	SUM1 = 12;
	 	SUM2= 3;
	 	SUM3 = 4;
	 	SUM4 = 2;
	 	SUM5 = 8;
	 	SUM6 = 1;
	 	SUM7 =3;
	 	SUM8 = 10;
	 #2	isSumReady = 1;
	 	#10 RESET = 1;
	 	#1 HREADY = 0;
	 	#1 HREADY = 1;
	

	 
	
	#5 HREADY = 0;
	#1 HREADY = 1;
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
