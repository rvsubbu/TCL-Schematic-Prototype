#!/usr/local/bin/wish

# (c)2013 R.V. Subramanyan All rights reserved.
# Developer: RV (rv@gmail.com)
# Prototype for Synopsys TCL/TK GUI Position
# Look at readme.txt for more info
# Starting point to create a netlist etc.

package require Tk
package require Tktable
package require tooltip
#package require struct

source [file join [file dirname [info script]] debug.tcl]
source [file join [file dirname [info script]] gui.tcl]
source [file join [file dirname [info script]] nl.tcl]
source [file join [file dirname [info script]] rr.tcl]
source [file join [file dirname [info script]] lookfeel.tcl]

# Sets the list of funcs to be debugged. Should be an empty list some day
RR::setRecordFuncs [list nl::makeInst nl::makeRgn nl::makeNet]
dbg::setStepFuncs [list]
dbg::setVerboseFuncs [list RR::logFuncCall RR::replay RR::setRecordFuncs]

#puts "RR:recordFuncs is $RR::recordFuncs"

#source [file join [file dirname [info script]] defaultdesign.tcl]
#source [file join [file dirname [info script]] random.tcl]
source [file join [file dirname [info script]] [lindex $::argv 0] ]

dbg::msg "numInsts is $nl::instId [dict values $nl::insts]\n"
dbg::msg "numRegions is $nl::rgnId[dict values $nl::rgns]\n"
dbg::msg "numNets is $nl::netId [dict values $nl::nets]\n"

#GUI::showInstConns inst5
#GUI::calcWinDimensions $GUI::cnvs

#nl::saveDesign "foo.tcl"
#nl::clearDesign
#nl::loadDesign "foo.tcl"

#GUI::assignInstToRgn inst4 rgn2 17500 8000

# Todo: I can't dismiss the messagebox below, why?
#GUI::error "error"

#GUI::clearDesign
#GUI::loadDesign shiftreg.tcl
