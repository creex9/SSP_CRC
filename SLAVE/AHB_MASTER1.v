`include "AHB_SLAVE.v"
module AHB_MASTER #(parameter DATA_WIDTH = 16,ADDR_WIDTH = 16)(

    //GENERAL SIGNALS
    input wire HCLK,
    input wire RESET,                       // Active LOW
    //AMBA AHB SIGNALS
    //Signals from SLAVE
  
    //CONF REGISTERs INPUTs
    input wire                   REGs_ready,// 1 when regs are available
    input wire [ADDR_WIDTH-1:0]  DADR,      //goes to HADDR, addres of data
    input wire [ADDR_WIDTH-1:0]  CADR,      //goes to HADDR, where save the sum
    input wire [1:0]             DLEN,    //Singl edata 16bit 00|one row 16bit x4 01| 10 Burst 2 rows 16bit x4 x2
    input wire                   isSumReady,
    input wire [DATA_WIDTH-1:0]  SUM1,
    input wire [DATA_WIDTH-1:0]  SUM2,
    input wire [DATA_WIDTH-1:0]  SUM3,
    input wire [DATA_WIDTH-1:0]  SUM4,
    input wire [DATA_WIDTH-1:0]  SUM5,
    input wire [DATA_WIDTH-1:0]  SUM6,
    input wire [DATA_WIDTH-1:0]  SUM7,
    input wire [DATA_WIDTH-1:0]  SUM8,
  //  input wire [DATA_WIDTH-1:0]  DATA_AHB_IN,
 //   input wire                   fifo_out_empty,
  //  input wire                   fifo_in_full,
  //  output reg                   rd_en_fifo_out,
    output reg [DATA_WIDTH-1:0]  DATA_AHB_OUT
 //   output reg                   wr_en_fifo_in
    //MASTER OUT

    
);
    //DLEN types
    localparam [1:0] SingleData = 2'b00;
    localparam [1:0] OneRow     = 2'b01;
    localparam [1:0] Brst2Row   = 2'b10;

    //HTRANS TYPES
    localparam [1:0] IDLE       = 2'b00;
    localparam [1:0] BUSY       = 2'b01;    //Not used
    localparam [1:0] NONSEQ     = 2'b10;
    localparam [1:0] SEQ        = 2'b11;

    //HBURST TYPES
    localparam [2:0] SINGLE     = 3'b000;
    localparam [2:0] INCR       = 3'b001;

    // NOT USED 
    localparam [2:0] WRAP4      = 3'b010;  
    localparam [2:0] INCR4      = 3'b011;   
    localparam [2:0] WRAP8      = 3'b100;   
    localparam [2:0] INCR8      = 3'b101;   
    localparam [2:0] WRAP16     = 3'b110;   
    localparam [2:0] INCR16     = 3'b111;
    //

    //AHB SIZES
    localparam [2:0] BYTE       = 3'b000;   // 8bits    NOTused
    localparam [2:0] HALFWORD   = 3'b001;   // 16bits   USED
    localparam [2:0] WORD       = 3'b010;   // 32bits   NOTused

    //Unused signals


    //Local REGs
    reg [3:0]             STATE;  //  //

    reg [ADDR_WIDTH-1:0]  rDADR;      //goes to HADDR, addres of data
    reg [ADDR_WIDTH-1:0]  rCADR;      //goes to HADDR, where save the sum
    reg [1:0]             rDLEN; 
    reg [DATA_WIDTH-1:0]  DataFromSlave[0:7];
    reg                   WhichBurst; // 0- oneRow, 1-doubleRow
    reg                   isFinished;
    reg [2:0]             iterator;
    reg [DATA_WIDTH-1:0] SUM [0:7];





     wire [DATA_WIDTH-1:0] HRDATA;     // DATA form Slave to master
     wire HREADY;                    // When HIGH-transfer finished, LOW to extend transfer
     wire HRESP;                       // Transfer status(HERE ALWAYS OKAY) : LOW- OKAY, HIGH-ERROR

     reg [ADDR_WIDTH-1:0] HADDR;      // ADDR to slave, lasts for a single HCLK cycle
    reg [DATA_WIDTH-1:0] HWDATA;     // DATA form Master to Slave
     reg [2:0] HBURST;                // BURST type : single incr wrap
     wire [2:0] HSIZE;                 // SIZE of transfer : byte, halfword or word - max 1024bits
     reg [1:0] HTRANS;              // Transfer type:  IDLE,BUSY,NONSEQ,SEQ
     reg HWRITE;                      // Transfer direction: HIGH-write, LOW-read
     wire HMASTLOCK;                    // HIGH when locked sequence
    assign HMASTLOCK            = 1'b0  ;
    assign HSIZE                = 3'b001;

    //States
    localparam [3:0] IDLE_STATE             = 4'b0000;
    localparam [3:0] SINGLE_ADDRES          = 4'b0001;
    localparam [3:0] SINGLE_DATA_READ       = 4'b0010;
    localparam [3:0] SINGLE_DATA_WRITE      = 4'b0100;
    localparam [3:0] SINGLE_STOP            = 4'b1000;
    localparam [3:0] BURST_START            = 4'b1110;
    localparam [3:0] BURST_RD_NEXT          = 4'b1100;
    localparam [3:0] BURST_WR_NEXT          = 4'b0011;
    localparam [3:0] BURST_STOP             = 4'b1010;

always @(*) begin
    SUM[0] = SUM1;
    SUM[1] = SUM2;
    SUM[2] = SUM3;
    SUM[3] = SUM4;
    SUM[4] = SUM5;
    SUM[5] = SUM6;
    SUM[6] = SUM7;
    SUM[7] = SUM8;
end


always @(posedge HCLK or negedge RESET ) begin
    if (RESET == 1'b0) begin
        HADDR   <= {ADDR_WIDTH{1'b0}};
        HWDATA  <= {DATA_WIDTH{1'b0}};
        HBURST  <=  SINGLE;
        HWRITE  <=  1'b0;
        STATE   <=  IDLE_STATE;
        HTRANS  <=  IDLE; 
    end
    else begin
        case(STATE)
    IDLE_STATE: begin
    HADDR = 16'd0;
  
        if(HREADY == 1'b1) begin
            if(isFinished == 0) begin
                if(HBURST == SINGLE)begin 
                    STATE  <= SINGLE_ADDRES;
                    HTRANS <= NONSEQ;
                end
                else begin  
                    STATE  <= BURST_START; 
                    iterator <= 0; 
                    HTRANS <= IDLE; 
                end
            end else begin
                STATE  <= IDLE_STATE;
                HTRANS <= IDLE;
                HWDATA <= 16'd0;
            end
        end
        else begin
            STATE  <= IDLE_STATE;
            HTRANS <= IDLE;
            HWDATA <= 16'd0;
        end
    end

    SINGLE_ADDRES: begin
        if(HREADY == 1'b1) begin
            if(HWRITE == 1'b1) begin
            STATE  <= SINGLE_DATA_WRITE;
            HTRANS <= NONSEQ;
            HADDR <= rCADR;
        end
        else begin
            STATE  <= SINGLE_DATA_READ;
            HTRANS <= NONSEQ;
            HADDR   <= rDADR;
        end
    end
    end

    SINGLE_DATA_READ: begin
        if(HREADY==1'b1) begin
            DataFromSlave[0] = HRDATA;
            isFinished <= 1;
            STATE <= SINGLE_STOP;
            HTRANS <= IDLE;

        end
        else begin
            STATE <= SINGLE_DATA_READ;
            HTRANS <= NONSEQ;
        end
    end

    SINGLE_DATA_WRITE: begin
        if(HREADY == 1'b1) begin
            HWDATA = SUM[0];
            isFinished <= 1;
            STATE <= SINGLE_STOP;
            HTRANS <= IDLE;
            HADDR <= 16'd0;

        end else begin
            HWDATA <= SUM[0];
            STATE <= SINGLE_DATA_WRITE;
            HTRANS <= NONSEQ;
        end
    end

    SINGLE_STOP: begin
        STATE <= IDLE_STATE;
        HTRANS <= IDLE;
        HWDATA <= 16'd0;
        HADDR <= 16'd0;

    end


    BURST_START: begin
        if(HREADY == 1'b1) begin
            if(HWRITE == 1'b1) begin
                HTRANS <= NONSEQ;
                STATE <= BURST_WR_NEXT;
                HADDR <= rCADR; 
                
            end else begin
                HTRANS <= NONSEQ;
                STATE <= BURST_RD_NEXT;
                HADDR <= rDADR;
            end 
       end    
       else begin
            STATE <= BURST_START;
            HTRANS <= NONSEQ;
        end

    end
    BURST_RD_NEXT: begin
        if(HREADY == 1'b1) begin
     //       if(!fifo_in_full) begin
            if(WhichBurst == 1'b0) begin
                if(iterator < 3) begin
                    STATE <= BURST_RD_NEXT;
                    HTRANS <= SEQ;
                    HADDR = HADDR + 1;
                    DataFromSlave[iterator] <= HRDATA;
                   DATA_AHB_OUT= HRDATA;
              //      wr_en_fifo_in = 1'b1;
                    iterator = iterator + 1;
                end else begin
                    STATE <= BURST_STOP;
                    DataFromSlave[iterator] <= HWDATA;
                    DATA_AHB_OUT = HRDATA;
             //       wr_en_fifo_in = 1'b1;
                    HADDR <= 16'd0;
                end
            end else begin
                if(iterator < 7) begin
                    STATE <= BURST_RD_NEXT;
                    HTRANS <= SEQ;
                    HADDR = HADDR + 1;
                    DataFromSlave[iterator] <= HRDATA;
                    DATA_AHB_OUT = HRDATA;
              //      wr_en_fifo_in = 1'b1;
                    iterator = iterator+1;
                end else begin
                    STATE <= BURST_STOP;
                    DataFromSlave[iterator] <= HWDATA;
                    DATA_AHB_OUT = HRDATA;
              //      wr_en_fifo_in = 1'b1;
                    HADDR <= 16'd0;                    
                end
           // end
            end
        end else begin
            STATE <= BURST_RD_NEXT;
        end
    end

        BURST_WR_NEXT: begin
        if(HREADY == 1'b1) begin
  //      if(!fifo_out_empty) begin
            if(WhichBurst == 1'b0) begin
                if(iterator < 3) begin
                    STATE <= BURST_WR_NEXT;
                    HTRANS <= SEQ;
                    HADDR = HADDR + 1;
                     HWDATA <= SUM[iterator];
              //      HWDATA <= DATA_AHB_IN;
               //     rd_en_fifo_out <= 1;
                    iterator = iterator + 1;
                end else begin
                    STATE <= BURST_STOP;
                    HWDATA <= SUM[iterator];//DATA_AHB_IN;
                 //   rd_en_fifo_out <= 1;
                    HADDR <= 16'd0;
                end
            end else begin
                if(iterator < 7) begin
                    STATE <= BURST_WR_NEXT;
                    HTRANS <= SEQ;
                    HADDR = HADDR + 1;
                     HWDATA <= SUM[iterator];
                   // rd_en_fifo_out <= 1;
                    iterator = iterator + 1;
                end else begin
                    STATE <= BURST_STOP;
                     HWDATA <= SUM[iterator];
                   // rd_en_fifo_out <= 1;
                    HADDR <= 16'd0;

                end
         //   end
            end
        end else begin
            STATE <= BURST_WR_NEXT;
        end
    end


    BURST_STOP: begin
        STATE <= IDLE_STATE;
        HTRANS <= IDLE;
        DATA_AHB_OUT = HRDATA;
        isFinished = 1'b1;
        iterator <= 0;
        HWDATA <= 16'd0;
        HADDR <= 16'd0;
      //  rd_en_fifo_out = 0;
     //   wr_en_fifo_in = 0;
        end


    endcase

    end
end

always @(posedge REGs_ready) begin
    rDLEN = DLEN;      
    rCADR = CADR;
    rDADR = DADR;
    isFinished = 1'b0;
end

always @(*) begin
    if(isSumReady == 1'b0) begin
        HWRITE = 1;  
    end else begin
        HWRITE = 0;
    end
end

always @(*) begin
    case(rDLEN)
    SingleData: begin
        HBURST = SINGLE;
        end

    OneRow: begin
        HBURST = INCR;
        WhichBurst = 1'b0;
    end

    Brst2Row: begin
        HBURST = INCR;
        WhichBurst = 1'b1;
    end
    endcase
    
end

AHB_SLAVE u1 (
    .HCLK(HCLK),
    .RESET(RESET),
    .HADDR(HADDR),
    .HWDATA(HWDATA),
    .HBURST(HBURST),
    .HSIZE(HSIZE),
    .HTRANS(HTRANS),
    .HWRITE(HWRITE),
    .HMASTLOCK(HMASTLOCK),
    .HRDATA(HRDATA),
    .HREADY(HREADY),
    .HRESP(HRESP)
    );

endmodule