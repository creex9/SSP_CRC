module AHB_MAST #(parameter [31:0] DATA_WIDTH = 32'd32,ADDR_WIDTH = 16)(

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
    input wire [1:0]             DLEN,    //Single data 16bit 00|one row 16bit x4 01| 10 Burst 2 rows 16bit x4 x2
    input wire                   isSumReady;
    input wire [DATA_WIDTH-1:0]  SUM;

    //MASTER OUT
    output reg [ADDR_WIDTH-1:0] HADDR,      // ADDR to slave, lasts for a single HCLK cycle
    output reg [DATA_WIDTH-1:0] HWDATA,     // DATA form Master to Slave
    output reg [2:0] HBURST,                // BURST type : single incr wrap
    output reg [2:0] HSIZE,                 // SIZE of transfer : byte, halfword or word - max 1024bits
    output reg [1:0] HTRANS,                // Transfer type:  IDLE,BUSY,NONSEQ,SEQ
    output reg HWRITE,                      // Transfer direction: HIGH-write, LOW-read
    output reg HMASTLOCK                    // HIGH when locked sequence
    
);
    //DLEN types
    localparam [1:0] SingleData      = 2'b00;
    localparam [1:0] OneRow          = 2'b01;
    localparam [1:0] Brst2Row        = 2'b10;

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
    reg [1:0]             NEXT_DLEN;

    reg [ADDR_WIDTH-1:0]  rDADR;      //goes to HADDR, addres of data
    reg [ADDR_WIDTH-1:0]  rCADR;      //goes to HADDR, where save the sum
    reg [1:0]             rDLEN; 
    reg [DATA_WIDTH-1:0]  DataFromSlave;

    //States
    localparam [3:0] IDLE_STATE     = 4'b0000;
    localparam [3:0] SINGLE_ADDRES  = 4'b0001;
    localparam [3:0] SINGLE_DATA    = 4'b0010;
    localparam [3:0] SINGLE_STOP    = 4'b0100;
    localparam [3:0] BURST_START    = 4'b1110;



always @(posedge HCLK or negedge RESET) begin
    if (RESET == 1'b0) begin
        HADDR   <= {ADDR_WIDTH{1'b0}};
        HWDATA  <= {DATA_WIDTH{1'b0}};
        HBURST  <=  SINGLE;
        HSIZE   <=  HALFWORD;
        HWRITE  <=  1'b0;
        HTRANS  <=  IDLE; 
    end
    else begin
        STATE   <= NEXT_STATE;
        HADDR   <= NEXT_ADDR;
        HWDATA  <= NEXT_HWDATA;
        HBURST  <= TMP_BURST;
        HSIZE   <= TMP_SIZE;
        HWRITE  <= NEXT_HWRITE;
        HTRANS  <= NEXT_HTRANS;
    end
end

always @(posedge REGs_ready) begin
    rDLEN <= DLEN;
    rCADR <= CADR;
    rDADR <= DADR;
    if(isSumReady == 1'b1)begin
        NEXT_HWRITE <= 1'b1;
    end
end


always @(*) begin

    case(STATE)
    IDLE_STATE: begin
        if(HREADY == 1'b1) begin
            if(rDLEN == SingleData)begin
                NEXT_STATE  = SINGLE_ADDRES;
                NEXT_HTRANS = NONSEQ;
            end
            else begin  
                NEXT_STATE  = BURST_START;     //poczatek bursta
                NEXT_HTRANS = NONSEQ;
            end
        end
        else begin
            NEXT_STATE  = IDLE_STATE;
            NEXT_HTRANS = IDLE;
        end
        end

    SINGLE_ADDRES: begin
        if(HREADY == 1'b1) begin
            if(NEXT_HWRITE == 1'b1) begin
            NEXT_STATE  = SINGLE_DATA_WRITE;
            NEXT_HTRANS = NONSEQ;
            NEXT_HWDATA = rDADR;
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
            DataFromSlave = HRDATA;
            NEXT_STATE = IDLE_STATE;
        end
        else begin
            NEXT_STATE = SINGLE_DATA;
            NEXT_STATE = NONSEQ;
        end

    end
    SINGLE_DATA_WRITE: begin
        if(HREADY == 1'b1) begin
            NEXT_HWDATA = SUM;
            NEXT_STATE = IDLE_STATE;
            NEXT_HTRANS = IDLE;
        end else begin
            NEXT_HWDATA = SUM;
            NEXT_STATE = SINGLE_DATA_WRITE;
            NEXT_HTRANS = NONSEQ;
        end


    end



    BURST_START: begin
        if () begin
            
        end




    end

end



endmodule