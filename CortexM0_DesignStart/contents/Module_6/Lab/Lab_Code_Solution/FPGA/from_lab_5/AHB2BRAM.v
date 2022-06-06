//  --========================================================================--
//  Version and Release Control Information:
//
//  File Name           : AHB2BRAM.v
//  File Revision       : 1.60
//
//  ----------------------------------------------------------------------------
//  Purpose             : Basic AHBLITE Internal Memory Default Size = 16KB
//                        
//  --========================================================================--
module AHB2MEM
#(parameter MEMWIDTH = 14)					// SIZE[Bytes] = 2 ^ MEMWIDTH[Bytes] = 2 ^ MEMWIDTH / 4[Entries]
  (
  //AHBLITE INTERFACE
  //Slave Select Signals
  input wire HSEL,
  //Global Signal
  input wire HCLK,
  input wire HRESETn,
  //Address, Control & Write Data
  input wire HREADY,
  input wire [31:0] HADDR,
  input wire [1:0] HTRANS,
  input wire HWRITE,
  input wire [2:0] HSIZE,
  
  input wire [31:0] HWDATA,
  // Transfer Response & Read Data
  output wire HREADYOUT,
  output reg [31:0] HRDATA
  );

  assign HREADYOUT = 1'b1; // Always ready

  // Memory Array
  reg [31:0] memory[0:(2**(MEMWIDTH-2)-1)];

  initial
  begin
    $readmemh("code.hex", memory);
  end
  
  // Registers to store Adress Phase Signals
  reg APhase_HSEL;
  reg APhase_HWRITE;
  reg [1:0] APhase_HTRANS;
  reg [31:0] APhase_HRADDR;
  reg [31:0] APhase_HWADDR;
  reg [2:0] APhase_HSIZE;

  // Sample the Address Phase   
  always @(posedge HCLK or negedge HRESETn)
  begin
    if(!HRESETn)
    begin
      APhase_HSEL <= 1'b0;
      APhase_HWRITE <= 1'b0;
      APhase_HTRANS <= 2'b00;
      APhase_HWADDR <= 32'h0;
      APhase_HSIZE <= 3'b000;
      APhase_HRADDR[MEMWIDTH-2:0] <= {(MEMWIDTH-1){1'b0}};
    end
    else if(HREADY)
    begin
      APhase_HSEL <= HSEL;
      APhase_HWRITE <= HWRITE;
      APhase_HTRANS <= HTRANS;
      APhase_HWADDR <= HADDR;
      APhase_HSIZE <= HSIZE;
      APhase_HRADDR[MEMWIDTH-2:0] <= HADDR[MEMWIDTH:2];
    end
  end

  // Decode the bytes lanes depending on HSIZE & HADDR[1:0]

  wire tx_byte = ~APhase_HSIZE[1] & ~APhase_HSIZE[0];
  wire tx_half = ~APhase_HSIZE[1] &  APhase_HSIZE[0];
  wire tx_word =  APhase_HSIZE[1];
  
  wire byte_at_00 = tx_byte & ~APhase_HWADDR[1] & ~APhase_HWADDR[0];
  wire byte_at_01 = tx_byte & ~APhase_HWADDR[1] &  APhase_HWADDR[0];
  wire byte_at_10 = tx_byte &  APhase_HWADDR[1] & ~APhase_HWADDR[0];
  wire byte_at_11 = tx_byte &  APhase_HWADDR[1] &  APhase_HWADDR[0];
  
  wire half_at_00 = tx_half & ~APhase_HWADDR[1];
  wire half_at_10 = tx_half &  APhase_HWADDR[1];
  
  wire word_at_00 = tx_word;
  
  wire byte0 = word_at_00 | half_at_00 | byte_at_00;
  wire byte1 = word_at_00 | half_at_00 | byte_at_01;
  wire byte2 = word_at_00 | half_at_10 | byte_at_10;
  wire byte3 = word_at_00 | half_at_10 | byte_at_11;

  always @ (posedge HCLK)
  begin
    if(APhase_HSEL & APhase_HWRITE & APhase_HTRANS[1])
	 begin
      if(byte0)
        memory[APhase_HWADDR[MEMWIDTH:2]][ 7: 0] <= HWDATA[ 7: 0];
      if(byte1)
        memory[APhase_HWADDR[MEMWIDTH:2]][15: 8] <= HWDATA[15: 8];
      if(byte2)
        memory[APhase_HWADDR[MEMWIDTH:2]][23:16] <= HWDATA[23:16];
      if(byte3)
        memory[APhase_HWADDR[MEMWIDTH:2]][31:24] <= HWDATA[31:24];
    end

    HRDATA = memory[HADDR[MEMWIDTH:2]];
  end

endmodule
