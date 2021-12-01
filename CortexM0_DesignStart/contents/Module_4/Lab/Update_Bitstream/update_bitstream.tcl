# # # # # # # # # # # # # # # # # # # # # # # # # # #
#
#	Script:			update_bitstream.tcl
#
#	Arguments:		None
#
#	Use:			Call "source update_bitstream.tcl" to create a new bitstream flashed with the updated code.data contents.
#					Designed for use with AHB2BRAM.v module in the ARM Cortx M0 project.
#
#	Requirements:	- The following files in the following locations:
#						-code.data existing within the project directory (same directory as this script) with correct data within,
#						-up-to-date bitstream called "AHBLITE_SYS.bit" exists in the implementation run directory,
#					
#					- The implemented design of the latest run is open.
#
# # # # # # # # # # # # # # # # # # # # # # # # # # #

#Source the header file if not defined. Defines procedures generate_mmi and generate_mem.
if {[info procs generate_mem] eq ""} {
	source update_bitstream_header.tcl
}

generate_mmi bram.mmi					;#Generate the .mmi file from the implemented design
generate_mem code.hex code.mem			;#Create the code.mem file from code.data

#Update the memory, reading from the latest bitstream in the implementation directory
set bitstream [get_property DIRECTORY [current_run -implementation]]; append bitstream "/AHBLITE_SYS.bit"
exec updatemem -debug --meminfo bram.mmi --data code.mem --bit $bitstream --proc my_bram --out reflash.bit -force