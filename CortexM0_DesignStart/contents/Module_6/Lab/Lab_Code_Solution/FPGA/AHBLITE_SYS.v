//////////////////////////////////////////////////////////////////////////////////
//END USER LICENCE AGREEMENT                                                    //
//                                                                              //
//Copyright (c) 2012, ARM All rights reserved.                                  //
//                                                                              //
//THIS END USER LICENCE AGREEMENT ("LICENCE") IS A LEGAL AGREEMENT BETWEEN      //
//YOU AND ARM LIMITED ("ARM") FOR THE USE OF THE SOFTWARE EXAMPLE ACCOMPANYING  //
//THIS LICENCE. ARM IS ONLY WILLING TO LICENSE THE SOFTWARE EXAMPLE TO YOU ON   //
//CONDITION THAT YOU ACCEPT ALL OF THE TERMS IN THIS LICENCE. BY INSTALLING OR  //
//OTHERWISE USING OR COPYING THE SOFTWARE EXAMPLE YOU INDICATE THAT YOU AGREE   //
//TO BE BOUND BY ALL OF THE TERMS OF THIS LICENCE. IF YOU DO NOT AGREE TO THE   //
//TERMS OF THIS LICENCE, ARM IS UNWILLING TO LICENSE THE SOFTWARE EXAMPLE TO    //
//YOU AND YOU MAY NOT INSTALL, USE OR COPY THE SOFTWARE EXAMPLE.                //
//                                                                              //
//ARM hereby grants to you, subject to the terms and conditions of this Licence,//
//a non-exclusive, worldwide, non-transferable, copyright licence only to       //
//redistribute and use in source and binary forms, with or without modification,//
//for academic purposes provided the following conditions are met:              //
//a) Redistributions of source code must retain the above copyright notice, this//
//list of conditions and the following disclaimer.                              //
//b) Redistributions in binary form must reproduce the above copyright notice,  //
//this list of conditions and the following disclaimer in the documentation     //
//and/or other materials provided with the distribution.                        //
//                                                                              //
//THIS SOFTWARE EXAMPLE IS PROVIDED BY THE COPYRIGHT HOLDER "AS IS" AND ARM     //
//EXPRESSLY DISCLAIMS ANY AND ALL WARRANTIES, EXPRESS OR IMPLIED, INCLUDING     //
//WITHOUT LIMITATION WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR //
//PURPOSE, WITH RESPECT TO THIS SOFTWARE EXAMPLE. IN NO EVENT SHALL ARM BE LIABLE/
//FOR ANY DIRECT, INDIRECT, INCIDENTAL, PUNITIVE, OR CONSEQUENTIAL DAMAGES OF ANY/
//KIND WHATSOEVER WITH RESPECT TO THE SOFTWARE EXAMPLE. ARM SHALL NOT BE LIABLE //
//FOR ANY CLAIMS, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, //
//TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE    //
//EXAMPLE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE EXAMPLE. FOR THE AVOIDANCE/
// OF DOUBT, NO PATENT LICENSES ARE BEING LICENSED UNDER THIS LICENSE AGREEMENT.//
//////////////////////////////////////////////////////////////////////////////////

module AHBLITE_SYS(
    input  wire          CLK,                // Oscillator - 100MHz
    input  wire          RESET,              // Reset

    // TO BOARD LEDs
    output wire    [7:0] LED,
    
   // VGA IO
    output wire    [2:0] vgaRed,
    output wire    [2:0] vgaGreen,
    output wire    [1:0] vgaBlue,
    output wire          Hsync,          // VGA Horizontal Sync
    output wire          Vsync,          // VGA Vertical Sync
   
    // TO UART
    input  wire          RsRx,
    output wire          RsTx,
	
	// Switch Inputs
    input  wire    [7:0] sw,
    
    // 7 Segment display
    output wire    [6:0] seg,
    output wire          dp,
    output wire    [3:0] an//,


    
    // Debug
    //input  wire          TDI,                // JTAG TDI
    //input  wire          TCK,                // SWD Clk / JTAG TCK
    //inout  wire          TMS,                // SWD I/O / JTAG TMS
    //output wire          TDO                 // SWV     / JTAG TDO
    );

    // Clock
    wire          fclk;                      // Free running clock
    // Reset
    wire          reset_n = !RESET;
	
    // Select signals
    wire    [3:0] mux_sel;

    wire          hsel_mem;
    wire          hsel_led;
    wire          hsel_vga;
    wire          hsel_uart;

    // Slave read data
    wire   [31:0] hrdata_mem;
    wire   [31:0] hrdata_led;
    wire   [31:0] hrdata_vga;
    wire   [31:0] hrdata_uart;

    // Slave hready
    wire          hready_mem;
    wire          hready_led;
    wire          hready_vga;
    wire          hready_uart;

    // CM-DS Sideband signals
    wire          lockup;
    wire          lockup_reset_req;
    wire          sys_reset_req;
    wire          txev;
    wire          sleeping;
    wire  [31:0]  irq;
    
    
    // Interrupt signals
    assign        irq = {32'b0};
    // assign        LED[7] = lockup;
    
	  // Clock divider, divide the frequency by two, hence less time constraint 
    reg clk_div;
    always @(posedge CLK)
    begin
        clk_div=~clk_div;
    end
    BUFG BUFG_CLK (
        .O(fclk),
        .I(clk_div)
    );
    
    // Reset synchronizer
    reg  [4:0]     reset_sync_reg;
    always @(posedge fclk or negedge reset_n)
    begin
        if (!reset_n)
            reset_sync_reg <= 5'b00000;
        else
        begin
            reset_sync_reg[3:0] <= {reset_sync_reg[2:0], 1'b1};
            reset_sync_reg[4] <= reset_sync_reg[2] & (~sys_reset_req);
        end
    end

    // CPU System Bus
    wire          hresetn = reset_sync_reg[4];
    wire   [31:0] haddrs; 
    wire    [2:0] hbursts; 
    wire          hmastlocks; 
    wire    [3:0] hprots; 
    wire    [2:0] hsizes; 
    wire    [1:0] htranss; 
    wire   [31:0] hwdatas; 
    wire          hwrites; 
    wire   [31:0] hrdatas; 
    wire          hreadys; 
    wire    [1:0] hresps = 2'b00;            // System generates no error response
    wire          exresps = 1'b0;

    // Debug signals (TDO pin is used for SWV unless JTAG mode is active)
    wire          dbg_tdo;                   // SWV / JTAG TDO
    wire          dbg_tdo_nen;               // SWV / JTAG TDO tristate enable (active low)
    wire          dbg_swdo;                  // SWD I/O 3-state output
    wire          dbg_swdo_en;               // SWD I/O 3-state enable
    wire          dbg_jtag_nsw;              // SWD in JTAG state (HIGH)
    wire          dbg_swo;                   // Serial wire viewer/output
    wire          tdo_enable     = !dbg_tdo_nen | !dbg_jtag_nsw;
    wire          tdo_tms        = dbg_jtag_nsw         ? dbg_tdo    : dbg_swo;
    assign        TMS            = dbg_swdo_en          ? dbg_swdo   : 1'bz;
    assign        TDO            = tdo_enable           ? tdo_tms    : 1'bz;

    // CoreSight requires a loopback from REQ to ACK for a minimal
    // debug power control implementation
    wire          cpu0cdbgpwrupreq;
    wire          cpu0cdbgpwrupack;
    assign        cpu0cdbgpwrupack = cpu0cdbgpwrupreq;

    // DesignStart simplified integration level
    CORTEXM0INTEGRATION u_CORTEXM0INTEGRATION (
        // CLOCK AND RESETS
        .FCLK          (fclk),               // Free running clock
        .SCLK          (fclk),               // System clock
        .HCLK          (fclk),               // AHB clock
        .DCLK          (fclk),               // Debug system clock
        .PORESETn      (reset_sync_reg[2]),  // Power on reset
        .DBGRESETn     (reset_sync_reg[3]),  // Debug reset
        .HRESETn       (hresetn),            // AHB and System reset

        // AHB-LITE MASTER PORT
        .HADDR         (haddrs),
        .HBURST        (hbursts),
        .HMASTLOCK     (hmastlocks),
        .HPROT         (hprots),
        .HSIZE         (hsizes),
        .HTRANS        (htranss),
        .HWDATA        (hwdatas),
        .HWRITE        (hwrites),
        .HRDATA        (hrdatas),
        .HREADY        (hreadys),
        .HRESP         (hresps),
        .HMASTER       (),

        // CODE SEQUENTIALITY AND SPECULATION
        .CODENSEQ      (),
        .CODEHINTDE    (),
        .SPECHTRANS    (),

        // DEBUG
        .nTRST         (1'b1),
        .SWCLKTCK      (TCK),
        .SWDITMS       (TMS),
        .TDI           (TDI),
        .SWDO          (dbg_swdo),
        .SWDOEN        (dbg_swdo_en),
        .TDO           (dbg_tdo),
        .nTDOEN        (dbg_tdo_nen),
        .DBGRESTART    (1'b0),               // Debug Restart request - Not needed in a single CPU system
        .DBGRESTARTED  (),
        .EDBGRQ        (1'b0),               // External Debug request to CPU
        .HALTED        (),

        // MISC
        .NMI           (1'b0),               // Non-maskable interrupt input
        .IRQ           (irq),                // Interrupt request inputs
        .TXEV          (),                   // Event output (SEV executed)
        .RXEV          (1'b0),               // Event input
        .LOCKUP        (lockup),             // Core is locked-up
        .SYSRESETREQ   (sys_reset_req),      // System reset request
        .STCALIB       ({1'b1,               // No alternative clock source
                         1'b0,               // Exact multiple of 10ms from FCLK
                         24'h007A11F}),      // Calibration value for SysTick for 50 MHz source
        .STCLKEN       (1'b0),               // SysTick SCLK clock disable
        .IRQLATENCY    (8'h00),
        .ECOREVNUM     (28'h0),

        // POWER MANAGEMENT
        .GATEHCLK      (),                   // When high, HCLK can be turned off
        .SLEEPING      (),                   // Core and NVIC sleeping
        .SLEEPDEEP     (),                   // The processor is in deep sleep mode
        .WAKEUP        (),                   // Active HIGH signal from WIC to the PMU that indicates a wake-up event has
                                             // occurred and the system requires clocks and power
        .WICSENSE      (),
        .SLEEPHOLDREQn (1'b1),               // Extend Sleep request
        .SLEEPHOLDACKn (),                   // Acknowledge for SLEEPHOLDREQn
        .WICENREQ      (1'b0),               // Active HIGH request for deep sleep to be WIC-based deep sleep
        .WICENACK      (),                   // Acknowledge for WICENREQ - WIC operation deep sleep mode
        .CDBGPWRUPREQ  (cpu0cdbgpwrupreq),   // Debug Power Domain up request
        .CDBGPWRUPACK  (cpu0cdbgpwrupack),   // Debug Power Domain up acknowledge.

        // SCAN IO
        .SE            (1'b0),               // DFT is tied off in this example
        .RSTBYPASS     (1'b0)                // Reset bypass - active high to disable internal generated reset for testing
    );

    // Address Decoder 
    AHBDCD uAHBDCD (
      .HADDR(haddrs),
     
      .HSEL_S0(hsel_mem),
      .HSEL_S1(hsel_vga),
      .HSEL_S2(hsel_uart),
      .HSEL_S3(),
      .HSEL_S4(),
      .HSEL_S5(),
      .HSEL_S6(),
      .HSEL_S7(),
      .HSEL_S8(),
      .HSEL_S9(),
      .HSEL_NOMAP(),
     
      .MUX_SEL(mux_sel[3:0])
    );

    // Slave to Master Mulitplexor
    AHBMUX uAHBMUX (
      .HCLK(fclk),
      .HRESETn(hresetn),
      .MUX_SEL(mux_sel[3:0]),
     
      .HRDATA_S0(hrdata_mem),
      .HRDATA_S1(hrdata_vga),
      .HRDATA_S2(hrdata_uart),
      .HRDATA_S3(),
      .HRDATA_S4(),
      .HRDATA_S5(),
      .HRDATA_S6(),
      .HRDATA_S7(),
      .HRDATA_S8(),
      .HRDATA_S9(),
      .HRDATA_NOMAP(32'hDEADBEEF),
     
      .HREADYOUT_S0(hready_mem),
      .HREADYOUT_S1(hready_vga),
      .HREADYOUT_S2(hready_uart),
      .HREADYOUT_S3(),
      .HREADYOUT_S4(),
      .HREADYOUT_S5(),
      .HREADYOUT_S6(1'b1),
      .HREADYOUT_S7(1'b1),
      .HREADYOUT_S8(1'b1),
      .HREADYOUT_S9(1'b1),
      .HREADYOUT_NOMAP(1'b1),
    
      .HRDATA(hrdatas),
      .HREADY(hreadys)
    );

    // AHBLite Peripherals
    
    // AHBLite Memory Controller 
    AHB2MEM uAHB2RAM (
      //AHBLITE Signals
      .HSEL(hsel_mem),
      .HCLK(fclk), 
      .HRESETn(hresetn), 
      .HREADY(hreadys),     
      .HADDR(haddrs),
      .HTRANS(htranss), 
      .HWRITE(hwrites),
      .HSIZE(hsizes),
      .HWDATA(hwdatas), 
      
      .HRDATA(hrdata_mem), 
      .HREADYOUT(hready_mem)
    );

            
    
  // AHBLite VGA Controller  
    AHBVGA uAHBVGA (
        .HCLK(fclk), 
        .HRESETn(hresetn), 
        .HADDR(haddrs), 
        .HWDATA(hwdatas), 
        .HREADY(hreadys), 
        .HWRITE(hwrites), 
        .HTRANS(htranss), 
        .HSEL(hsel_vga), 
        .HRDATA(hrdata_vga), 
        .HREADYOUT(hready_vga), 
        .hsync(Hsync), 
        .vsync(Vsync), 
        .rgb({vgaRed,vgaGreen,vgaBlue})
    );
    
      // AHBLite UART Peripheral 
    AHBUART uAHBUART(
        .HCLK(fclk),
        .HRESETn(hresetn),
        .HADDR(haddrs),
        .HTRANS(htranss),
        .HWDATA(hwdatas),
        .HWRITE(hwrites),
        .HREADY(hreadys),
        .HREADYOUT(hready_uart),
        .HRDATA(hrdata_uart),
        .HSEL(hsel_uart),
    
        .RsRx(RsRx),
        .RsTx(RsTx)
    );
    
            // AHBLite 7-segment Pheripheral
         /*	 
    AHB7SEGDEC uAHB7SEGDEC(
        .HCLK(fclk),
        .HRESETn(hresetn),
        .HADDR(haddrs),
        .HTRANS(htranss),
        .HWDATA(hwdatas),
        .HWRITE(hwrites),
        .HREADY(hreadys),
        .HREADYOUT(hready_7seg),
        .HRDATA(hrdata_7seg),
        .HSEL(hsel_7seg),
    
        .seg(seg),
        .an(an),
        .dp(dp)
    );   
    */ 
            
    // AHBLite timer
    /*
    AHBTIMER uAHBTIMER(
        .HCLK(fclk),
        .HRESETn(hresetn),
        .HADDR(haddrs),
        .HTRANS(htranss),
        .HWDATA(hwdatas),
        .HWRITE(hwrites),
        .HREADY(hreadys),
        .HREADYOUT(hready_timer),
        .HRDATA(hrdata_timer),
        .HSEL(hsel_timer)
    );
    */
    // AHBLite GPIO    
    /*AHBGPIO uAHBGPIO(
        .HCLK(fclk),
        .HRESETn(hresetn),
        .HADDR(haddrs),
        .HWRITE(hwrites),
        .HWDATA(hwdatas),
        .HTRANS(htranss),
        .HSEL(hsel_gpio),
        .HREADY(hreadys),
        .GPIOIN({8'b00000000, sw[7:0]}),
        .HREADYOUT(hready_gpio),
        .HRDATA(hrdata_gpio),
        .GPIOOUT(LED[7:0])
    );
    */
        
 
    
endmodule
