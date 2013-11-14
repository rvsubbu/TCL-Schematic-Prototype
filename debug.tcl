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
#	Bug: Currently, namespaces are ignored. This means that func names
#		cannot be shared across namespaces
# Iteration 2:
#	A much simpler rewrite using existing TCL data structs to print call
#	stack etc.
#	Namespace bug mentioned above is automatically fixed.
#		Add a simplistic watch mechanism (display values @ every func entry)


namespace eval dbg {
	array set verboseFuncs {}; # funcs whose puts msgs will be printed out
	array set setFuncs {}; # funcs to be stepped through
	set verboseFuncs(main) false
	set stepFuncs(main) false

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

	proc step {name {yesno 1}} {
		set mode [expr {$yesno? "add" : "remove"}]
		trace $mode execution $name {enterstep leavestep} dbg::interact
	}

	proc interact args {
		if {[lindex $args end] eq "leavestep"} {
			puts ==>[lindex $args 2]
			return
		}
		puts -nonewline "$args --"
		while 1 {
			puts -nonewline "> "
			flush stdout
			gets stdin cmd
			if {$cmd eq "c" || $cmd eq ""} break
			catch {uplevel 1 $cmd} res
			if {[string length $res]} {puts $res}
		}
	}
	proc printArgsOnEntry {args} {
		set func [lindex $args 0]
		puts "PAOE: func is $func"
		set currFunc [lindex [lindex $args 0] 0]
		set funcArgs [lrange [lindex $args 0] 1 end]
		puts "$currFunc entered with $funcArgs";
	}

	proc setStepFuncs {listOfFuncs} {
		# step through the given funcs
		foreach func $listOfFuncs {
			if { "main" != $func } {
				set dbg::stepFuncs($func) true
				dbg::step $func
			} else {
				# Can't step through main right now.
			}
		}
	}

	proc setVerboseFuncs {listOfFuncs} {
		# set the debug status of the given funcs to true
		foreach func $listOfFuncs {
			set dbg::verboseFuncs($func) true
			if { "main" != $func } {
				trace add execution $func enter dbg::printArgsOnEntry
			} else {
				puts "Script args are $::argv"
			}
		}
	}

	proc msg {msg} {
		# msg gets printed only if the current calling func's debug status is true
		set callStackDepth [info level]
		if { 1 == $callStackDepth } {
			set currFunc "main"; # Like the C "main" function.
		} else {
			set currFunc [lindex [info level -1] 0]
		}
		if { "" != [array names dbg::verboseFuncs "$currFunc"] } {
			if { $dbg::verboseFuncs($currFunc) } {
				puts "$currFunc: $msg"
			}
		}
	}
}

