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


module vga_console(
  input wire clk,
  input wire resetn,
  input wire [9:0] pixel_x,
  input wire [9:0] pixel_y,
  
  input wire font_we,         //font write
  input wire [7:0] font_data, //input 7-bit ascii value
  
  output reg [7:0] text_rgb,  //output color
  output reg scroll           //signals scrolling
);

  //Screen tile parameters
  localparam MAX_X = 30;      //Number of horizontal tiles
  localparam MAX_Y = 30;      //Number of tile rows
  
  //Font ROM
  wire [10:0] rom_addr;       
  wire [6:0] char_addr;
  wire [3:0] row_addr;
  wire [2:0] bit_addr;
  wire [7:0] font_word;
  wire font_bit;
  
  //Dual port RAM
  wire [11:0] addr_r;
  wire [11:0] addr_w;
  wire [6:0] din;
  wire [6:0] dout;
  
  //Cursor
  reg [6:0] cur_x_reg;
  wire [6:0] cur_x_next;
  reg [4:0] cur_y_reg;
  wire [4:0] cur_y_next;
//  wire cursor_on;
  
  //pixel buffers
  reg [9:0] pixel_x1;
  reg [9:0] pixel_x2;
  reg [9:0] pixel_y1;
  reg [9:0] pixel_y2;
  
  wire [7:0] font_rgb;      //color for text
  wire [7:0] font_inv_rgb;  //color for text with cursor on top
  
  reg current_state;
  reg next_state;
  
  wire return_key;      //carriage return or '\n'
  wire new_line;        //move cursor to next line
  
  //reg scroll;
  reg scroll_next;
  reg [4:0] yn;         //row count
  reg [4:0] yn_next;    
  reg [6:0] xn;         //horizontal count
  reg [6:0] xn_next;
  
  //Module Instantiation
  font_rom ufont_rom(
    .clk(clk),
    .addr(rom_addr),
    .data(font_word)
  );
  
  dual_port_ram_sync
  #(.ADDR_WIDTH(12), .DATA_WIDTH(7))
  uvideo_ram
  ( .clk(clk),
    .reset_n(resetn),
    .we(we),
    .addr_a(addr_w),
    .addr_b(addr_r),
    .din_a(din),
    .dout_a(),
    .dout_b(dout)
  );
  
  //State Machine for cursor and pixel buffer
  always @ (posedge clk, negedge resetn)
  begin
    if(!resetn)
      begin
        cur_x_reg <= 0;
        cur_y_reg <= 0;
      end
    else
      begin
        cur_x_reg <= cur_x_next;
        cur_y_reg <= cur_y_next;
        pixel_x1 <= pixel_x;
        pixel_x2 <= pixel_x1;
        pixel_y1 <= pixel_y;
        pixel_y2 <= pixel_y1;
      end
  end
  

  //Font ROM Access
  assign row_addr = pixel_y[3:0];           //row value
  assign rom_addr = {char_addr,row_addr};   //ascii value and row of character
  assign bit_addr = pixel_x2[2:0]; //delayed
  assign font_bit = font_word[~bit_addr];   //output from font rom
  
  //Return key found
  assign return_key = (din == 6'b001101 || din == 6'b001010) && ~scroll; // Return || "\n"
  
  //Backspace
  assign back_space = (din == 6'b001000);
  
  //New line logic
  assign new_line = font_we && ((cur_x_reg == MAX_X-1) || return_key);
        
  //Next Cursor Position logic   
  assign cur_x_next = (new_line) ? 2 :
                      (back_space && cur_x_reg) ? cur_x_reg - 1 :
                      (font_we && ~back_space && ~scroll) ? cur_x_reg + 1 : cur_x_reg;
  
  assign cur_y_next = (cur_y_reg == MAX_Y-1) ? cur_y_reg :
                       ((new_line) ? cur_y_reg + 1 : cur_y_reg );

  //Color Generation
  assign font_rgb = (font_bit) ? 8'b00011100 : 8'b00000000; //green:black
  assign font_inv_rgb = (font_bit) ? 8'b0000000 : 8'b00011100; //black:green
  
  //Display logic for cursor
//  assign cursor_on = (pixel_x2[9:3] == cur_x_reg) && (pixel_y2[8:4] == cur_y_reg);
  
  //RAM Write Enable
  assign we = font_we || scroll;
  
  //Display combinational logic
  always @*
  begin
        text_rgb = font_rgb;
  end
  
  //Console state machine
  always @(posedge clk, negedge resetn)
    if(!resetn)
      begin
        scroll <= 1'b0;
        yn <= 5'b00000;
        xn <= 7'b0000000;
        current_state <= 1'b0;
      end
    else
      begin
        scroll <= scroll_next;
        yn <= yn_next;
        xn <= xn_next;
        current_state <= next_state;
      end
  
  //Console next state logic
  always @*
  begin
    scroll_next = scroll;
    xn_next = xn;
    yn_next = yn;
    next_state = current_state;
    case(current_state)
      1'b0: //Waits for a new line and the cursor on the last line of the screen
        if(new_line && (cur_y_reg == MAX_Y-1))
          begin
            scroll_next = 1'b1;
            next_state = 1'b1;
            yn_next = 0;
            xn_next = 7'b1111111; //Delayed by one cycle
          end
        else
          scroll_next = 1'b0;
      1'b1: //Counts through every tile and refreshes
      begin
        if(xn_next == MAX_X)
          begin
            xn_next = 7'b1111111; //Delayed by one cycle
            yn_next = yn + 1'b1;
            if(yn_next == MAX_Y)
              begin
                next_state = 1'b0;
                scroll_next = 0;
              end
          end
        else
          xn_next = xn + 1'b1;
        
          
      end    
    endcase
  end
  
  
  //RAM Write 
  assign addr_w = (scroll) ? {yn,xn} : {cur_y_reg, cur_x_reg}; 
  assign din = (scroll) ?  dout : font_data[6:0];
  //RAM Read
  assign addr_r =(scroll) ? {yn+1'b1,xn_next} : {pixel_y[8:4],pixel_x[9:3]};
  assign char_addr = dout;
  
  

endmodule
