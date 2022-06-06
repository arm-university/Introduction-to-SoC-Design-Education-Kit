//////////////////////////////////////////////////////////////////////////////////
//END USER LICENCE AGREEMENT                                                    //
//                                                                              //
//Copyright (c) 2012, ARM All rights reserved.                                  //
//                                                                              //
//THIS END USER LICENCE AGREEMENT (“LICENCE”) IS A LEGAL AGREEMENT BETWEEN      //
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


module AHBVGA(
  input wire HCLK,
  input wire HRESETn,
  input wire [31:0] HADDR,
  input wire [31:0] HWDATA,
  input wire HREADY,
  input wire HWRITE,
  input wire [1:0] HTRANS,
  input wire HSEL,
  
  output wire [31:0] HRDATA,
  output wire HREADYOUT,
  
  output wire hsync,
  output wire vsync,
  output wire [7:0] rgb
);
  //Register locations
  localparam IMAGEADDR = 4'hA;
  localparam CONSOLEADDR = 4'h0;
  
  //Internal AHB signals
  reg last_HWRITE;
  reg last_HSEL;
  reg [1:0] last_HTRANS;
  reg [31:0] last_HADDR;
  
  wire [7:0] console_rgb; //console rgb signal              
  wire [9:0] pixel_x;     //current x pixel
  wire [9:0] pixel_y;     //current y pixel
  
  reg console_write;      //write to console
  reg [7:0] console_wdata;//data to write to console
  reg image_write;        //write to image
  reg [7:0] image_wdata;  //data to write to image
  
  wire [7:0] image_rgb;   //image color
  
  wire scroll;            //scrolling signal
  
  wire sel_console;       
  wire sel_image;
  reg [7:0] cin;
  
  
  always @(posedge HCLK)
  if(HREADY)
    begin
      last_HADDR <= HADDR;
      last_HWRITE <= HWRITE;
      last_HSEL <= HSEL;
      last_HTRANS <= HTRANS;
    end
    
  //Give time for the screen to refresh before writing
  assign HREADYOUT = ~scroll;   
 
  //VGA interface: control the synchronization and color signals for a particular resolution
  VGAInterface uVGAInterface (
    .CLK(HCLK), 
    .COLOUR_IN(cin), 
    .cout(rgb), 
    .hs(hsync), 
    .vs(vsync), 
    .addrh(pixel_x), 
    .addrv(pixel_y)
    );

  //VGA console module: output the pixels in the text region
  vga_console uvga_console(
    .clk(HCLK),
    .resetn(HRESETn),
    .pixel_x(pixel_x),
    .pixel_y(pixel_y),
    .text_rgb(console_rgb),
    .font_we(console_write),
    .font_data(console_wdata),
    .scroll(scroll)
    );
  
  //VGA image buffer: output the pixels in the image region
  vga_image uvga_image(
    .clk(HCLK),
    .resetn(HRESETn),
    .address(last_HADDR[15:2]),
    .pixel_x(pixel_x),
    .pixel_y(pixel_y),
    .image_we(image_write),
    .image_data(image_wdata),
    .image_rgb(image_rgb)
    );

  assign sel_console = (last_HADDR[23:0]== 12'h000000000000);
  assign sel_image = (last_HADDR[23:0] != 12'h000000000000);
  
  //Set console write and write data
  always @(posedge HCLK, negedge HRESETn)
  begin
    if(!HRESETn)
      begin
        console_write <= 0;
        console_wdata <= 0;
      end
    else if(last_HWRITE & last_HSEL & last_HTRANS[1] & HREADYOUT & sel_console)
      begin
        console_write <= 1'b1;
        console_wdata <= HWDATA[7:0];
      end
    else
      begin
        console_write <= 1'b0;
        console_wdata <= 0;
      end
  end
  
  //Set image write and image write data
  always @(posedge HCLK, negedge HRESETn)
  begin
    if(!HRESETn)
      begin
        image_write <= 0;
        image_wdata <= 0;
      end
    else if(last_HWRITE & last_HSEL & last_HTRANS[1] & HREADYOUT & sel_image)
      begin
        image_write <= 1'b1;
        image_wdata <= HWDATA[7:0];
      end
    else
      begin
        image_write <= 1'b0;
        image_wdata <= 0;
      end
  end
  
  //Select the rgb color for a particular region
  always @*
  begin
    if(!HRESETn)
      cin <= 8'h00;
    else 
      if(pixel_x[9:0]< 240 )
        cin <= console_rgb ;
      else
        cin <= image_rgb;
  end

endmodule
  
  
