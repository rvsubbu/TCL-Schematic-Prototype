#!/usr/local/bin/wish

# (c)2013 R.V. Subramanyan All rights reserved.
# Developer: RV (rv@gmail.com)
# Debug functions

namespace eval dbg {
	array set fns {}; # array to store tcl function names
	set currFn main; # main is not a TCL "proc", but the first proc anyway.
	set fns(main) false
	# Todo: Make a call stack
	# Todo: Add a watch variable mechanism

	proc initFns {} {
		# Read all fn names and set their debug status to false
		# Todo: Generate the function list dynamically
		#	grep proc *.tcl to find all function names
		# Todo: Currently, namespaces are ignored. This means that func
		#	names cannot be shared across namespaces
		#set dir [file dirname [info script]]
#% eval [list exec grep p] [glob *.tcl]

		#set getFnsCmd "grep proc $dir/*.tcl | cut -d\" \" -f2 > fns.txt"
		#exec $getFnsCmd
		#eval [list exec grep proc] [glob $dir/*.tcl]
		set fp [open fns.txt r]
		set allfns [read $fp]
		set fns [split $allfns "\n"]
		foreach f $fns {
			set dbg::fns($f) false
			#set dbg::fns($f) true
		}
		close $fp
	}

# Call enterFn when you enter any func
# enterFn returns the prev func's name on the call stack.
# Call exitFn when you exit any func (Watch out for return stmts)
# Set the prev func's name that was returned by enterFn here.
	proc enterFn {fnName} {
		set prevFn $dbg::currFn
		set dbg::currFn $fnName
		return $prevFn
	}

	proc exitFn {fnName} {
		set dbg::currFn $fnName
	}

	proc debugFns {listOfFns} {
		# set the debug status of the given funcs to true
		foreach fn $listOfFns {
			set dbg::fns($fn) true
		}
	}

	proc msg {msg} {
		# msg gets printed only if the current func's debug status is true
		if { $dbg::fns($dbg::currFn) } {
			puts "$dbg::currFn $msg"
		}
	}
}

