# # # # # # # # # # # # # # # # # # # # # # # # # # #
#
# 	Procedure: 	generate_mmi
#
#	Arguments:	- mmi_file
#					Name of the mmi file to be generated
#
#	Use: 		Generate the .mmi file using the location information from the implemented design.
# 
# # # # # # # # # # # # # # # # # # # # # # # # # # #

proc generate_mmi {mmi_file} {
	#If the current open implemented design does not equal the latest implementation run, open the implemented design
	if {[current_run -implementation] != [current_design]} { open_run [current_run -implementation] }
	#Create a list of the BRAM locations in loc_list.
	set list_mem [get_property LOC [get_cells -hierarchical -filter { PRIMITIVE_TYPE =~ BMEM.bram.* && NAME =~ "uAHB2RAM*" }]]
	set loc_list {}
	foreach x $list_mem {
		lappend loc_list [string map {RAMB36_ {}} $x]
	}
	#Write the header to the .mmi file.
	set DataWidth "\t\t\t\t\t<DataWidth MSB=\"31\" LSB=\"0\"/>"
	set AddressRange "\t\t\t\t\t<AddressRange Begin=\"0\" End=\"4095\"/>"
	set Parity "\t\t\t\t\t<Parity ON=\"false\" NumBits=\"0\"/>"
	set CloseBitLane "\t\t\t\t</BitLane>"
	set PreBitLane "\t\t\t\t<BitLane MemType=\"RAMB36\" Placement=\""
	set PostBitLane "\">"
	set fd [open "mmi.tmp" w]
	puts $fd "<?xml version=\"1.0\" encoding=\"UTF-8\"?>"
	puts $fd "<MemInfo Version=\"1\" Minor=\"15\">"
	puts $fd "\t<Processor Endianness=\"Little\" InstPath=\"my_bram\">"
	puts $fd "\t\t<AddressSpace Name=\"memory\" Begin=\"0\" End=\"16384\">"
	puts $fd "\t\t\t<BusBlock>"
	set bString ""
	#Create a new BitLane object in the .mmi for each BRAM block in loc_list.
	foreach BitLane $loc_list {
		set bString ""
		append bString $PreBitLane $BitLane $PostBitLane
		puts $fd $bString
		puts $fd $DataWidth
		puts $fd $AddressRange
		puts $fd $Parity
		puts $fd $CloseBitLane
	}
	#Write the footer to the .mmi file.
	puts $fd "\t\t\t</BusBlock>"
	puts $fd "\t\t</AddressSpace>"
	puts $fd "\t</Processor>"
	puts $fd "\t<Config>"
	puts $fd "\t\t<Option Name=\"Part\" Val=\"xc7a35tcpg236-1\"/>"
	puts $fd "\t</Config>"
	puts $fd "\t<DRC>"
	puts $fd "\t\t<Rule Name=\"RDADDRCHANGE\" Val=\"false\"/>"
	puts $fd "\t</DRC>"
	puts $fd "</MemInfo>"
	#Move the file from mmi.tmp to bram.mmi, deleting the temporary file.
	close $fd
	file copy -force mmi.tmp bram.mmi
	file delete mmi.tmp
}

# # # # # # # # # # # # # # # # # # # # # # # # # # #
#
# 	Procedure: 	byte_reverse
#
#	Arguments:	- str
#					Hexadecimal string of integer number of bytes
#
#	Use: 		Reverse the order of the bytes in a hexadecimal string.
#				Called by generate_mem when converting the .data file to .mem due to memory mapping in .mem format.
# 
# # # # # # # # # # # # # # # # # # # # # # # # # # #

proc byteReverse {str} {
	set strLength [string length $str]
	set bytesPerString [ expr {$strLength / 2} ]
	set reverseString {}
	#Firstly, reverse the string: {0 1 2 3 4 5 6 7} -> {7 6 5 4 3 2 1 0}
	for {set i 0} {$i < $strLength} {incr i} {
		append reverseString [string index $str [expr {$strLength - $i - 1}]]
	}
	#Swap the order of the nibbles: {7 6 5 4 3 2 1 0} -> {6 7 4 5 2 3 0 1}
	set nibbleSwapString {}
	for {set i 0} {$i < $bytesPerString} {incr i} {
		append nibbleSwapString [string index $reverseString [expr {2*$i + 1}]]
		append nibbleSwapString [string index $reverseString [expr {2*$i }]]
	}
	set nibbleSwapString
}

# # # # # # # # # # # # # # # # # # # # # # # # # # #
#
#	Procedure:	generate_mem
#
#	Arguments:	- data_file
#					The name of the .data file containing the memory initialization data in hex.
#				- mem_file
#					The name of the .mem output file to be created.
#					This name is parameterized in update_bitstream.tcl to be passed to the updatemem command.
#
#	Use:		Convert the .data file to the .mem file, performing all of the byte mapping.
#
#	Terms:		Chunk - four 32-bit words (8 character hex strings) which are written in packets to the mem_file.
#
# # # # # # # # # # # # # # # # # # # # # # # # # # #

proc generate_mem {data_file mem_file} {
	#Write the Memory Address start prefix to the .mem file
	set prefix "@0000"
	set fo [open code.tmp w]
	puts $fo $prefix
	set fi [open $data_file r] 	;#Open the file specified by data_file {code.data} for read.
	set bytes_per_word 4		;#Bytes per word - hardcoded to 4 (32-bit words). Used for timing when to write chunks.
	set ChunksDone 1			;#ChunksDone is set to <0 at EOF. Used to break out of while loop.
	set chunkCounter 0			;#chunkCounter counts up to 4 for each word read in. Once it reaches four the chunk is written to the mem_file.
	set chunkList {0 0 0 0}
	while {($ChunksDone >= 0)} {
		set ChunksDone [gets $fi line]	;#chunksDone contains the latest line of the data_file.
		#If the loop has reached EOF, pad the chunkList with "00000000" and write it to the output file before exiting loop.
		if {$ChunksDone < 0} {
			for {set i $chunkCounter} {$i < $bytes_per_word} {incr i} {
				lset chunkList $i "00000000"
			}
			#Write the padded chunk to the output file.
			for {set i 0} {$i < $bytes_per_word} {incr i} {
				set lineStr {}
				foreach line $chunkList {
					append lineStr [string index $line [expr {2*$i} ]]
					append lineStr [string index $line [expr {2*$i + 1} ]]
				}
				puts $fo $lineStr
			}
		#If the line was not EOF, add the reversed word to the chunkList and increment the loop indicating valid word.
		} else {
			lset chunkList $chunkCounter [byteReverse $line]
			incr chunkCounter
		}
		#If the number of valid words in the chunk is 4, write the chunk to memory and reset the counter.
		if {$chunkCounter == 4} {
			set chunkCounter 0
			# Write the full chunk to the output file.
			for {set i 0} {$i < $bytes_per_word} {incr i} {
				set lineStr {}
				foreach line $chunkList {
					append lineStr [string index $line [expr {2*$i} ]]
					append lineStr [string index $line [expr {2*$i + 1} ]]
				}
				puts $fo $lineStr
			}
		}
	}
	close $fi	;#Close the file objects.
	close $fo
	file copy -force code.tmp $mem_file		;#Overwrite the existing .mem with the .tmp file
	file delete code.tmp					;#Delete code.tmp
}