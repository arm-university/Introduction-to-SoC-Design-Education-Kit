# # # # # # # # # # # # # # # # # # # # # # # # # # #
#
# END USER LICENCE AGREEMENT                                                    
#                                                                               
# Copyright (c) 2019, ARM All rights reserved.                                  
#                                                                               
# THIS END USER LICENCE AGREEMENT ("LICENCE") IS A LEGAL AGREEMENT BETWEEN      
# YOU AND ARM LIMITED ("ARM") FOR THE USE OF THE SOFTWARE EXAMPLE ACCOMPANYING  
# THIS LICENCE. ARM IS ONLY WILLING TO LICENSE THE SOFTWARE EXAMPLE TO YOU ON   
# CONDITION THAT YOU ACCEPT ALL OF THE TERMS IN THIS LICENCE. BY INSTALLING OR  
# OTHERWISE USING OR COPYING THE SOFTWARE EXAMPLE YOU INDICATE THAT YOU AGREE   
# TO BE BOUND BY ALL OF THE TERMS OF THIS LICENCE. IF YOU DO NOT AGREE TO THE   
# TERMS OF THIS LICENCE, ARM IS UNWILLING TO LICENSE THE SOFTWARE EXAMPLE TO    
# YOU AND YOU MAY NOT INSTALL, USE OR COPY THE SOFTWARE EXAMPLE.                
#                                                                               
# ARM hereby grants to you, subject to the terms and conditions of this Licence,
# a non-exclusive, worldwide, non-transferable, copyright licence only to       
# redistribute and use in source and binary forms, with or without modification,
# for academic purposes provided the following conditions are met:              
# a) Redistributions of source code must retain the above copyright notice, this
# list of conditions and the following disclaimer.                              
# b) Redistributions in binary form must reproduce the above copyright notice,  
# this list of conditions and the following disclaimer in the documentation     
# and/or other materials provided with the distribution.                        
#                                                                               
# THIS SOFTWARE EXAMPLE IS PROVIDED BY THE COPYRIGHT HOLDER "AS IS" AND ARM     
# EXPRESSLY DISCLAIMS ANY AND ALL WARRANTIES, EXPRESS OR IMPLIED, INCLUDING     
# WITHOUT LIMITATION WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR 
# PURPOSE, WITH RESPECT TO THIS SOFTWARE EXAMPLE. IN NO EVENT SHALL ARM BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, PUNITIVE, OR CONSEQUENTIAL DAMAGES OF ANY
# KIND WHATSOEVER WITH RESPECT TO THE SOFTWARE EXAMPLE. ARM SHALL NOT BE LIABLE 
# FOR ANY CLAIMS, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, 
# TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE    
# EXAMPLE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE EXAMPLE. FOR THE AVOIDANCE
#  OF DOUBT, NO PATENT LICENSES ARE BEING LICENSED UNDER THIS LICENSE AGREEMENT.
# 
#	Script:			update_bitstream.tcl
#
#	Arguments:		None
#
#	Use:			Call "source update_bitstream.tcl" to create a new bitstream 
#                   flashed with the updated code.data contents.
#					Designed for use with AHB2BRAM.v module in the ARM Cortx M0 
#                   project.
#
#	Requirements:	- The following files in the following locations:
#						-code.data existing within the project directory 
#                        (same directory as this script) with correct data within,
#						-up-to-date bitstream called "AHBLITE_SYS.bit" exists in 
#                        the implementation run directory,
#					
#					- The implemented design of the latest run is open.
#                   - This script may only work with specific version of Vivado.
#                     This script was tested on Vivado in 2019. 
#
# # # # # # # # # # # # # # # # # # # # # # # # # # #

#Source the header file if not defined. 
#Defines procedures generate_mmi and generate_mem.
if {[info procs generate_mem] eq ""} {
	source update_bitstream_header.tcl
}

generate_mmi bram.mmi					;#Generate the .mmi file from the implemented design
generate_mem code.hex code.mem			;#Create the code.mem file from code.data

#Update the memory, reading from the latest bitstream in the implementation directory
set bitstream [get_property DIRECTORY [current_run -implementation]]; append bitstream "/AHBLITE_SYS.bit"
exec updatemem -debug --meminfo bram.mmi --data code.mem --bit $bitstream --proc my_bram --out reflash.bit -force