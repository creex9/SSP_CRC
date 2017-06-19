module AHB_SLAVE #(parameter DATA_WIDTH = 16,ADDR_WIDTH = 16)(

    //GENERAL SIGNALS
    input wire HCLK,
    input wire RESET,                       // Active LOW
    //AMBA AHB SIGNALS
 
    //Signals from MASTER
    input wire [ADDR_WIDTH-1:0] HADDR,      // ADDR to slave, lasts for a single HCLK cycle
    input wire [DATA_WIDTH-1:0] HWDATA,     // DATA form Master to Slave
    input wire [2:0] HBURST,                // BURST type : single incr wrap
    input wire [2:0] HSIZE,                 // SIZE of transfer : byte, halfword or word - max 1024bits
    input wire [1:0] HTRANS,                // Transfer type:  IDLE,BUSY,NONSEQ,SEQ
    input wire HWRITE,                      // Transfer direction: HIGH-write, LOW-read
    input wire HMASTLOCK ,                   // HIGH when locked sequence

       //Signals from SLAVE
    output reg [DATA_WIDTH-1:0] HRDATA,     // DATA form Slave to master
    output reg HREADY,                      // When HIGH-transfer finished, LOW to extend transfer
    output wire HRESP                       // Transfer status(HERE ALWAYS OKAY) : LOW- OKAY, HIGH-ERROR

    
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

    //AHB SIZES
    localparam [2:0] HALFWORD   = 3'b001;   // 16bits   USED


    //Unused signals
    assign  HRESP               = 1'b0;
   // assign  HREADY              = 1'b1;

    //Local REGs
    reg [3:0]             STATE;  //  //

    reg [DATA_WIDTH-1:0]  RAM [0:65535];
   
    reg [15:0]            adres;
    wire[DATA_WIDTH-1:0] ram1;
    wire[DATA_WIDTH-1:0] ram2;
    wire[DATA_WIDTH-1:0] ram3;
    wire[DATA_WIDTH-1:0] ram4;
    wire[DATA_WIDTH-1:0] ram5;
    assign ram1  = RAM[10] ;
    assign ram2  = RAM[11] ;
    assign ram3  = RAM[12] ;
    assign ram4  = RAM[13] ;
    assign ram5  = RAM[20] ;
    reg [3:0] iterator;



    //States
    localparam [3:0] IDLE_STATE             = 4'b0000;
    localparam [3:0] SINGLE_WRITE           = 4'b0001;
    localparam [3:0] SINGLE_READ            = 4'b0010;

    localparam [3:0] BURST_READ             = 4'b1100;
    localparam [3:0] BURST_WRITE            = 4'b0011;

always @(*) begin
  adres = HADDR;
end



always @(posedge HCLK or negedge RESET ) begin
    if (RESET == 1'b0) begin
        HRDATA  <= {DATA_WIDTH{1'b0}};
        STATE   <=  IDLE_STATE;
        HREADY <= 1'b1;
        RAM [0] = 0;
        RAM [1] = 20;
        RAM [2] = 30;
        RAM [3] = 40;
        RAM [4] = 50;
        RAM [5] = 60;
        RAM [6] = 70;
        RAM [7] = 80;
        RAM [8] = 90;
        RAM [9] = 100;
        RAM [10] = 110;
        RAM [11] = 120;
        RAM [12] = 130;
        RAM [13] = 140;
        RAM [14] = 150;
        RAM [15] = 160;
        RAM [16] = 170;
        RAM [17] = 180;
        RAM [18] = 190;
        RAM [19] = 200;

    end
    else begin
        case(STATE)
    IDLE_STATE: begin
    if(HTRANS != IDLE ) begin
        if(HWRITE == 1'b1) begin
            if(HBURST == SINGLE) begin
                STATE <= SINGLE_WRITE;
            end else begin
                STATE <= BURST_WRITE;
            end
        end else begin
            if(HBURST == SINGLE) begin
                STATE <= SINGLE_READ;
            end else begin
                STATE <= BURST_READ;
               HRDATA = RAM[adres];
            end
        end
     end else begin
         STATE<= IDLE_STATE;
         HRDATA <= 16'd0;
         iterator = 0;
     end
     end

    SINGLE_WRITE: begin
        RAM[HADDR] <= HWDATA;   //dziala
        STATE <= IDLE_STATE;
     end
    SINGLE_READ: begin
        HRDATA <= RAM[adres];
        STATE <= IDLE_STATE;
     end
    BURST_READ: begin
        HRDATA = RAM[adres];
        iterator = iterator+1;
        if(HTRANS != IDLE && iterator < 3) begin
            STATE<= BURST_READ;
        end else begin
            STATE<= IDLE_STATE;
        end
    end
    BURST_WRITE: begin              //DZIALA
        if(HTRANS != IDLE) begin
            STATE<= BURST_WRITE;
            RAM[adres]<= HWDATA;
        end else begin
            STATE<= IDLE_STATE;

        end
    end





endcase
  end
    
end


endmodule