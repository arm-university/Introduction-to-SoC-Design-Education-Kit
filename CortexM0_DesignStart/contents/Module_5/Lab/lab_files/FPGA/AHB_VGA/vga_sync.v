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

module VGAInterface(
    input CLK,
    input [7:0] COLOUR_IN,
    output reg [7:0] cout,
    output reg hs,
    output reg vs,
    output reg [9:0] addrh,
    output reg [9:0] addrv
    );


// Time in Vertical Lines
parameter VertTimeToPulseWidthEnd  = 10'd2;
parameter VertTimeToBackPorchEnd   = 10'd31;
parameter VertTimeToDisplayTimeEnd = 10'd511;
parameter VertTimeToFrontPorchEnd  = 10'd521;

// Time in Horizontal Lines
parameter HorzTimeToPulseWidthEnd  = 10'd96;
parameter HorzTimeToBackPorchEnd   = 10'd144;
parameter HorzTimeToDisplayTimeEnd = 10'd784;
parameter HorzTimeToFrontPorchEnd  = 10'd800;

wire TrigHOut, TrigDiv;
wire [9:0] HorzCount;
wire [9:0] VertCount;

//Divide the clock frequency
GenericCounter  #(.COUNTER_WIDTH(1), .COUNTER_MAX(1))
FreqDivider
(
	.CLK(CLK),
	.RESET(1'b0),
	.ENABLE_IN(1'b1),
	.TRIG_OUT(TrigDiv)
);

//Horizontal counter
GenericCounter  #(.COUNTER_WIDTH(10), .COUNTER_MAX(HorzTimeToFrontPorchEnd))
HorzAddrCounter
(
	.CLK(CLK),
	.RESET(1'b0),
	.ENABLE_IN(TrigDiv),
	.TRIG_OUT(TrigHOut),
	.COUNT(HorzCount)
);

//Vertical counter
GenericCounter  #(.COUNTER_WIDTH(10), .COUNTER_MAX(VertTimeToFrontPorchEnd))
VertAddrCounter
(
	.CLK(CLK),
	.RESET(1'b0),
	.ENABLE_IN(TrigHOut),
	.COUNT(VertCount)
);

//Synchronisation signals
always@(posedge CLK) begin
	if(HorzCount<HorzTimeToPulseWidthEnd)
			hs <= 1'b0;
	else
			hs <= 1'b1;

	if(VertCount<VertTimeToPulseWidthEnd)
			vs <= 1'b0;
	else
			vs <= 1'b1;
end

//Color signals
always@(posedge CLK) begin
	if ( ( (HorzCount >= HorzTimeToBackPorchEnd ) && (HorzCount < HorzTimeToDisplayTimeEnd) ) &&
		  ( (VertCount >= VertTimeToBackPorchEnd ) && (VertCount < VertTimeToDisplayTimeEnd) ) ) 
		cout <= COLOUR_IN;
	else
		cout <= 8'b00000000;
end

//output horizontal and vertical addresses 
always@(posedge CLK)begin
	if ((HorzCount>HorzTimeToBackPorchEnd)&&(HorzCount<HorzTimeToDisplayTimeEnd))
		addrh<=HorzCount-HorzTimeToBackPorchEnd;
	else
		addrh<=10'b0000000000;
end	
	
always@(posedge CLK)begin
	if ((VertCount>VertTimeToBackPorchEnd)&&(VertCount<VertTimeToDisplayTimeEnd))
		addrv<=VertCount-VertTimeToBackPorchEnd;
	else
		addrv<=10'b0000000000;
end

endmodule
