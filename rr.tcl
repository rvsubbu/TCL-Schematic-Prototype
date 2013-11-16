#!/usr/local/bin/wish

# (c)2013 R.V. Subramanyan All rights reserved.
# Developer: RV (rv@gmail.com)
# Function for Record and Replay

# Basic idea:
#	User decides which functions to record and set thems in recordFuncs array
#	Add a trace enter to each such func
#	Log the func with all its args
#	Replay the log and execute the func back.

namespace eval RR {
	array set recordFuncs {}
	set recFP [open "record.txt" w]

	proc logFuncCall {args} {
		set func [lindex $args 0]
		dbg::msg "Recording $args"
		puts $RR::recFP $args
	}

	proc setRecordFuncs {listOfFuncs} {
		# step through the given funcs
		foreach func $listOfFuncs {
			dbg::msg "Adding $func to recordFuncs"
			set RR::recordFuncs($func) true
			trace add execution $func enter RR::logFuncCall
			#trace add execution $func leavestep RR::logFuncCall
		}
	}

	proc replay {} {
		set repFP [open "replay.txt" r]
		set cmds [split $design "\n"]
		foreach cmd $cmds {
			dbg::msg "RR: cmd is $cmd"
			dbg::msg "RR: status is [eval $cmd]"
		}
	}
}

