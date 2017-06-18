module AHB_MASTER #(parameter [31:0] DATA_WIDTH = 32'd16,ADDR_WIDTH = 16)(

    //GENERAL SIGNALS
    input wire HCLK,
    input wire RESET,                       // Active LOW
    //AMBA AHB SIGNALS
    //Signals from SLAVE
    input wire [DATA_WIDTH-1:0] HRDATA,     // DATA form Slave to master
    input wire HREADY,                      // When HIGH-transfer finished, LOW to extend transfer
    input wire HRESP,                       // Transfer status(HERE ALWAYS OKAY) : LOW- OKAY, HIGH-ERROR

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
    //MASTER OUT
    output reg [ADDR_WIDTH-1:0] HADDR,      // ADDR to slave, lasts for a single HCLK cycle
    output reg [DATA_WIDTH-1:0] HWDATA,     // DATA form Master to Slave
    output reg [2:0] HBURST,                // BURST type : single incr wrap
    output wire [2:0] HSIZE,                 // SIZE of transfer : byte, halfword or word - max 1024bits
    output reg [1:0] HTRANS,                // Transfer type:  IDLE,BUSY,NONSEQ,SEQ
    output reg HWRITE,                      // Transfer direction: HIGH-write, LOW-read
    output wire HMASTLOCK                    // HIGH when locked sequence
    
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
    assign HMASTLOCK            = 1'b0  ;
    assign HSIZE                = 3'b001;

    //Local REGs
    reg [ADDR_WIDTH-1:0]  NEXT_ADDR;
    reg [DATA_WIDTH-1:0]  NEXT_HWDATA;    
    reg [3:0]             STATE;
    reg [3:0]             NEXT_STATE;
    reg [2:0]             TMP_SIZE;     //
    reg [2:0]             TMP_BURST;    //
    reg [1:0]             NEXT_HTRANS;
    reg                   NEXT_HWRITE;
    reg [ADDR_WIDTH-1:0]  WHERE_SAVE;
    reg [1:0]             NEXT_DLEN ;

    reg [ADDR_WIDTH-1:0]  rDADR;      //goes to HADDR, addres of data
    reg [ADDR_WIDTH-1:0]  rCADR;      //goes to HADDR, where save the sum
    reg [1:0]             rDLEN; 
    reg [DATA_WIDTH-1:0]  DataFromSlave[0:7];
    reg                   WhichBurst; // 0- oneRow, 1-doubleRow
    reg                   isFinished;
    reg [2:0]             iterator;
    reg [DATA_WIDTH-1:0] SUM [0:7];


    //States
    localparam [3:0] IDLE_STATE             = 4'b0000;
    localparam [3:0] SINGLE_ADDRES          = 4'b0001;
    localparam [3:0] SINGLE_DATA_READ       = 4'b0010;
    localparam [3:0] SINGLE_DATA_WRITE      = 4'b0100;
    localparam [3:0] SINGLE_STOP            = 4'b1000;
    localparam [3:0] BURST_START            = 4'b1110;
    localparam [3:0] BURST_RD_NEXT          = 4'b1100;
    localparam [3:0] BURST_WR_NEXT          = 4'b0011;
    localparam [3:0] BURST_STOP             = 4'b1110;

always@(*) begin
    SUM[0] = SUM1;
    SUM[1] = SUM2;
    SUM[2] = SUM3;
    SUM[3] = SUM4;
    SUM[4] = SUM5;
    SUM[5] = SUM6;
    SUM[6] = SUM7;
    SUM[7] = SUM8;
end


always @(posedge HCLK or negedge RESET) begin
    if (RESET == 1'b0) begin
        HADDR   <= {ADDR_WIDTH{1'b0}};
        HWDATA  <= {DATA_WIDTH{1'b0}};
        HBURST  <=  SINGLE;
        HWRITE  <=  1'b0;
        STATE   <=  IDLE_STATE;
        NEXT_STATE <= IDLE_STATE;
        HTRANS  <=  IDLE; 
    end
    else begin
        STATE   <= NEXT_STATE;
        HADDR   <= NEXT_ADDR;
        HWDATA  <= NEXT_HWDATA;
        HBURST  <= TMP_BURST;
        HWRITE  <= NEXT_HWRITE;
        HTRANS  <= NEXT_HTRANS;
    end
end

always @(posedge REGs_ready) begin
    rDLEN = DLEN;               //WORKING !
    rCADR = CADR;
    rDADR = DADR;
    isFinished = 1'b0;
end

always @(*) begin
    if(isSumReady == 1'b1) begin
        NEXT_HWRITE = 1;       //WORKING
    end else begin
        NEXT_HWRITE = 0;
    end
end

always @(*) begin
    case(rDLEN)
    SingleData: begin
        TMP_BURST = SINGLE;
        end
                            //WORKING
    OneRow: begin
        TMP_BURST = INCR;
        WhichBurst = 1'b0;
    end

    Brst2Row: begin
        TMP_BURST = INCR;
        WhichBurst = 1'b1;
    end
    endcase
    
end



always @(*) begin

    case(STATE)
    IDLE_STATE: begin
    NEXT_ADDR = 16'bzzzzzz;
        if(HREADY == 1'b1) begin
            if(isFinished == 0) begin
                if(TMP_BURST == SINGLE)begin //was rDLEN
                    NEXT_STATE  = SINGLE_ADDRES;
                    NEXT_HTRANS = NONSEQ;
                end
                else begin  
                    NEXT_STATE  = BURST_START; 
                    iterator = 0; 
                    NEXT_HTRANS = IDLE;
                end
            end else begin
                NEXT_STATE  = IDLE_STATE;
                NEXT_HTRANS = IDLE;
                NEXT_HWDATA = 16'bzzzzzz;
            end
        end
        else begin
            NEXT_STATE  = IDLE_STATE;
            NEXT_HTRANS = IDLE;
            NEXT_HWDATA = 16'bzzzzzz;
        end
    end

    SINGLE_ADDRES: begin
        if(HREADY == 1'b1) begin
            if(NEXT_HWRITE == 1'b1) begin
            NEXT_STATE  = SINGLE_DATA_WRITE;
            NEXT_HTRANS = NONSEQ;
            NEXT_ADDR = rCADR;
        end
        else begin
            NEXT_STATE  = SINGLE_DATA_READ;
            NEXT_HTRANS = NONSEQ;
            NEXT_ADDR   = rDADR;
        end
    end
    end

    SINGLE_DATA_READ: begin
        if(HREADY==1'b1) begin
            DataFromSlave[0] = HRDATA;
            isFinished = 1;
            NEXT_STATE = SINGLE_STOP;
          ////  NEXT_STATE = IDLE_STATE;
            NEXT_HTRANS = IDLE;
        end
        else begin
            NEXT_STATE = SINGLE_DATA_READ;
            NEXT_HTRANS = NONSEQ;
        end
    end

    SINGLE_DATA_WRITE: begin
        if(HREADY == 1'b1) begin
            NEXT_HWDATA = SUM[0];
            isFinished = 1;
            NEXT_STATE = SINGLE_STOP;
     //       NEXT_STATE = IDLE_STATE;
            NEXT_HTRANS = IDLE;
        end else begin
            NEXT_HWDATA = SUM[0];
            NEXT_STATE = SINGLE_DATA_WRITE;
            NEXT_HTRANS = NONSEQ;
        end
    end

    SINGLE_STOP: begin
        NEXT_STATE = IDLE_STATE;
        NEXT_HTRANS = IDLE;

    end


    BURST_START: begin
        if(HREADY == 1'b1) begin
            if(NEXT_HWRITE == 1'b1) begin
                NEXT_HTRANS = NONSEQ;
                NEXT_STATE = BURST_WR_NEXT;
                NEXT_ADDR = rCADR; 
                
            end else begin
                NEXT_HTRANS = NONSEQ;
                NEXT_STATE = BURST_RD_NEXT;
                NEXT_ADDR = rDADR;
            end 
        end    
        else begin
             NEXT_STATE = BURST_START;
             NEXT_HTRANS = NONSEQ;
        end

    end
    BURST_RD_NEXT: begin
        if(HREADY == 1'b1) begin
            NEXT_HTRANS = SEQ;
            NEXT_ADDR = NEXT_ADDR + 1;
            DataFromSlave[iterator] = HRDATA;
            if(WhichBurst == 1'b0) begin
                if(iterator <= 4) begin
                    NEXT_STATE = BURST_RD_NEXT;
                    iterator = iterator + 1;
                end else begin
                    NEXT_STATE = BURST_STOP;
                end
            end else begin
                if(iterator <= 8) begin
                    NEXT_STATE = BURST_RD_NEXT;
                    iterator = iterator+1;
                end else begin
                    NEXT_STATE = BURST_STOP;
                end
            end
        end else begin
            NEXT_STATE = BURST_RD_NEXT;
        end
    end

        BURST_WR_NEXT: begin
        if(HREADY == 1'b1) begin
            NEXT_HTRANS = SEQ;
            NEXT_ADDR = NEXT_ADDR + 1;
            NEXT_HWDATA = SUM[iterator];
            if(WhichBurst == 1'b0) begin
                if(iterator <= 4) begin
                    NEXT_STATE = BURST_WR_NEXT;
                    iterator = iterator + 1;
                end else begin
                    NEXT_STATE = BURST_STOP;
                end
            end else begin
                if(iterator <= 8) begin
                    NEXT_STATE = BURST_WR_NEXT;
                    iterator = iterator+1;
                end else begin
                    NEXT_STATE = BURST_STOP;
                end
            end
        end else begin
            NEXT_STATE = BURST_WR_NEXT;
        end
    end


    BURST_STOP: begin
        NEXT_STATE = IDLE_STATE;
        NEXT_HTRANS = IDLE;
    end


    endcase

end



endmodule