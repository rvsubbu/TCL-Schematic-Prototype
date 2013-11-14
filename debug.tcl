#!/usr/local/bin/wish

# (c)2013 R.V. Subramanyan All rights reserved.
# Developer: RV (rv@gmail.com)
# Debug functions

# Basic idea:
#	No debugger, extensive use of puts
#	Need a way to urn on and off puts from functions, otherwise the output
#		is too verbose.
#	Initialize a list of funcs to be debugged.
#	All funcs call enterFn as their very first stmt.
#	enterFN stores its arg - the current func name in the dbg::currFn var.
#	enterFn returns the prev "currFunc". Store it in a local var.
#	No direct puts call, puts wrapped around a dbg::msg function
#	Only if currFn is in the list of funcs to be debugged, print the msg
#	Before any (explicit and implicit) return stmts in the caller func, call#		exitFn with the prevFn name as an arg. exitFn resets the currFn
#		value to prevFn in the call stack.
#	Todo:
#		Keep an actual call stack
#		Add a watch mechanism (display values at every enterFn and exitFn)
#	Bug: Currently, namespaces are ignored. This means that func names
#		cannot be shared across namespaces
# Iteration 2:
# 	A much simpler rewrite using existing TCL data structs to print call
#	stack etc.
#	Namespace bug mentioned above is automatically fixed.


namespace eval dbg {
	array set fns {}; # array to store tcl function names
	set currFn main; # main is not a TCL "proc", but the first proc anyway.
	set fns(main) false

	proc getCallStack {} {
    	set stack "Stack trace:\n"
    	for {set i 1} {$i < [info level]} {incr i} {
        	set lvl [info level -$i]
        	set procName [lindex $lvl 0]
        	append stack [string repeat " " $i]$procName
        	foreach val [lrange $lvl 1 end] arg [info args $procName] {
            	if {$val eq ""} {
					# Default arg.
                	info default $procName $arg val
					set val "$val (Default)"
            	}
            	append stack " $arg='$val'"
        	}
        	append stack "\n"
    	}
    	return $stack
	}

	proc debugFns {listOfFns} {
		# set the debug status of the given funcs to true
		foreach fn $listOfFns {
			set dbg::fns($fn) true
		}
	}

	proc msg {msg} {
		# msg gets printed only if the current calling func's debug status is true
		set callStackDepth [info level]
		if { 1 == $callStackDepth } {
			# msg being printed from the "main" function
        	set currFn [lindex [info level 0] 0]
		} else {
        	set currFn [lindex [info level -1] 0]
		}
		if { "" != [array names dbg::fns "$currFn"] } {
			if { $dbg::fns($dbg::currFn) } {
				puts "$dbg::currFn $msg"
			}
		}
	}
}

