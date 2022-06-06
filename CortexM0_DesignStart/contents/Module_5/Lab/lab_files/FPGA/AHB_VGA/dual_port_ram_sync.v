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

module dual_port_ram_sync
  #(
      parameter ADDR_WIDTH = 6,
      parameter DATA_WIDTH = 8
  )
  (
  input wire clk,
  input wire reset_n,
  input wire we,
  input wire [ADDR_WIDTH-1:0] addr_a,
  input wire [ADDR_WIDTH-1:0] addr_b,
  input wire [DATA_WIDTH-1:0] din_a,
  
  output wire [DATA_WIDTH-1:0] dout_a,
  output wire [DATA_WIDTH-1:0] dout_b
  );

  reg [DATA_WIDTH-1:0] ram [2**ADDR_WIDTH-1:0];
  reg [ADDR_WIDTH-1:0] addr_a_reg;
  reg [ADDR_WIDTH-1:0] addr_b_reg;
  
  reg [ADDR_WIDTH:0] reset_addr;
  reg [1:0] reset_n_buf;
  
  always @ (posedge clk)
  begin
    // Clear each data when reset
    reset_n_buf = {reset_n_buf[0], reset_n};
    if (reset_n_buf == 2'b10)
    begin
      reset_addr <= 0;
    end
    else if ((!we) && (reset_addr[ADDR_WIDTH] == 1'b0))
    begin
      reset_addr <= reset_addr + 1;
    end

    if (we || (reset_addr[ADDR_WIDTH] == 1'b0))
      ram[we ? addr_a : reset_addr] <= we ? din_a : {DATA_WIDTH{1'b0}};
    addr_a_reg <= addr_a;
    addr_b_reg <= addr_b;
  end
  
  assign dout_a = ram[addr_a_reg];
  assign dout_b = ram[addr_b_reg];
  
endmodule
