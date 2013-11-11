TCL-Schematic-Prototype
=======================

Prototype for Synopsys TCL/TK GUI Position
Schematic viewer for Vineet Rashingkar
version 0.2
RV
Start Date: Nov4, 2013
Deadline: Nov7, 2013
Actual Finish: Nov8, 2013
Language: TCL/TK

Netlist commands:
	nlInst name <-type type> <-numInputs numInputs> <-numOutputs numOutputs> <-parent parentInst> <-x x> <-y y> <-width width> <-height height> <-region region>
	nlNet <-name name> -from fromPort -to toPort
	nlRegion <-x x> <-y y> <-width width> <-height height>

GUI commands:
	loadDesign fileName
	saveDesign fileName
	clearDesign
	designInfo
	selectInst instName
	unselectInst
	instInfo instName
	showInstConnections
	selectRegion rgnName (Not yet implemented)
	unselectRegion (Not yet implemented)
	regionInfo rgnName (Not yet implemented)
	selectNet netName (Not yet implemented)
	unselectNet (Not yet implemented)
	netInfo (Not yet implemented)

