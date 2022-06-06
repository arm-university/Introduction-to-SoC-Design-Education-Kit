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

 
module AHBMUX(
  //GLOBAL CLOCK & RESET
  input wire HCLK,
  input wire HRESETn,
   
  //MUX SELECT FROM ADDRESS DECODER
  input wire [3:0] MUX_SEL,

  //READ DATA FROM ALL THE SLAVES  
  input wire [31:0] HRDATA_S0,		
  input wire [31:0] HRDATA_S1,
  input wire [31:0] HRDATA_S2,
  input wire [31:0] HRDATA_S3,
  input wire [31:0] HRDATA_S4,
  input wire [31:0] HRDATA_S5,
  input wire [31:0] HRDATA_S6,
  input wire [31:0] HRDATA_S7,
  input wire [31:0] HRDATA_S8,
  input wire [31:0] HRDATA_S9,
  input wire [31:0] HRDATA_NOMAP,

  //READYOUT FROM ALL THE SLAVES  
  input wire HREADYOUT_S0,
  input wire HREADYOUT_S1,
  input wire HREADYOUT_S2,
  input wire HREADYOUT_S3,
  input wire HREADYOUT_S4,
  input wire HREADYOUT_S5,
  input wire HREADYOUT_S6,
  input wire HREADYOUT_S7,
  input wire HREADYOUT_S8,
  input wire HREADYOUT_S9,
  input wire HREADYOUT_NOMAP,
 
  //MULTIPLEXED HREADY & HRDATA TO MASTER
  output reg HREADY,
  output reg [31:0] HRDATA
);

 
  reg [3:0] APHASE_MUX_SEL;			// LATCH THE ADDRESS PHASE MUX_SELECT
												// TO SEND THE APPROPRIATE RESPONSE & RDATA
												// IN THE DATA PHASE
  always@ (posedge HCLK or negedge HRESETn)
  begin
    if(!HRESETn)
      APHASE_MUX_SEL <= 4'h0;
    else if(HREADY)						// NOTE: ALL THE CONTROL SIGNALS ARE VALID ONLY IF HREADY = 1'b1
      APHASE_MUX_SEL <= MUX_SEL;
  end


  always@*
  begin
    case(APHASE_MUX_SEL)
      4'b0000: begin						// SELECT SLAVE0 RESPONSE & DATA IF PREVIOUS APHASE WAS FOR S0
        HRDATA = HRDATA_S0;
        HREADY = HREADYOUT_S0;
      end
      4'b0001: begin
        HRDATA = HRDATA_S1;
        HREADY = HREADYOUT_S1;
      end
      4'b0010: begin
        HRDATA = HRDATA_S2;
        HREADY = HREADYOUT_S2;
      end
      4'b0011: begin
        HRDATA = HRDATA_S3;
        HREADY = HREADYOUT_S3;
      end
      4'b0100: begin
        HRDATA = HRDATA_S4;
        HREADY = HREADYOUT_S4;
      end
      4'b0101: begin
        HRDATA = HRDATA_S5;
        HREADY = HREADYOUT_S5;
      end
      4'b0110: begin
        HRDATA = HRDATA_S6;
        HREADY = HREADYOUT_S6;
      end
      4'b0111: begin
        HRDATA = HRDATA_S7;
        HREADY = HREADYOUT_S7;
      end
      4'b1000: begin
        HRDATA = HRDATA_S8;
        HREADY = HREADYOUT_S8;
      end
      4'b1001: begin
        HRDATA = HRDATA_S9;
        HREADY = HREADYOUT_S9;
      end
      default: begin            
        HRDATA = HRDATA_NOMAP;
        HREADY = HREADYOUT_NOMAP;
      end
    endcase
    
  end


endmodule
